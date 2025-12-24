/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::layer;

import std::io;
import std::core::mem;
import std::collections::list;
import openpngstudio::layer::static_layer;
import openpngstudio::layer::animated;
import openpngstudio::animation;
import openpngstudio::ui::wm;
import openpngstudio::ui::icons;
import openpngstudio::ui::line_edit;
import nk;
import raylib5::rl;
import std::math @public;

struct Manager (wm::Window) {
    List{Layer} layers;
    animation::Manager animation_manager;
    isz selected_layer;
    Config conf;

    int id;
}

const OUTLINE_WIDTH = 10.0f;

fn void Manager.init(&self, WindowManager *wm, Allocator alloc)
{
    self.layers.init(alloc);
    self.id = wm.next_id();
    self.animation_manager.init(wm.next_id(), alloc);
    self.selected_layer = -1;
    self.conf.init(wm.next_id(), &self.animation_manager);

    wm.register("Layer Manager", self);
    wm.register("Global Animation Configuration", &self.animation_manager);
    wm.register("Layer Configuration", &self.conf);
}

fn void Manager.add_layer(&self, StaticLayer *layer)
{
    Layer l;
    if (layer.props.is_animated) {
        l = (AnimatedLayer*) layer;
    } else {
        l = layer;
    }

    self.layers.push(l);
}

fn int Manager.get_id(&self) @dynamic => self.id;

fn void Manager.draw(&self, WindowManager *wm, nk::Context *ctx) @dynamic
{
    float win_width = nk::window_get_width(ctx);
    float min_width = math::max(win_width * 0.49f, 250.0f);

    nk::layout_row_template_begin(ctx, 35);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_variable(ctx, min_width);
    nk::layout_row_template_end(ctx);

    nk::label(ctx, "Global Animations: ", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Global Animations", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);
        if (nk::button_label(ctx, "Configure")) {
            wm.show(&self.animation_manager);
        }
        nk::group_end(ctx);
    }

    nk::Rect bounds = nk::window_get_content_region(ctx);
    bounds.h -= 45 * 2;
    nk::layout_row_dynamic(ctx, bounds.h, 1);
    bool res = nk::group_begin(ctx, "Layers", 0);

    foreach (i, layer : self.layers) {
        Properties *layer_props = layer.get_properties();

        nk::layout_row_template_begin(ctx, 30);
        nk::layout_row_template_push_dynamic(ctx);
        nk::layout_row_template_push_static(ctx, 30);
        nk::layout_row_template_push_static(ctx, 30);
        nk::layout_row_template_end(ctx);

        line_edit::line_edit_draw(&layer_props.name, ctx);

        if (nk::button_image(ctx, icons::get(CFG))) {
            self.selected_layer = i;
            wm.show(&self.conf);
            self.conf.selected = self.layers[self.selected_layer];
        }

        if (nk::button_image(ctx, icons::get(TRASH))) {
            State *layer_state = layer.get_state();
            layer_state.prepare_for_deletion = true;
            self.selected_layer = -1;
        }
    }

    if (res) nk::group_end(ctx);

    if (self.selected_layer == -1) nk::widget_disable_begin(ctx);

    nk::layout_row_template_begin(ctx, 30);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_static(ctx, 30);
    nk::layout_row_template_push_static(ctx, 30);
    nk::layout_row_template_end(ctx);

    nk::spacer(ctx);

    isz i = self.selected_layer;
    Layer layer = i != -1 ? self.layers[i] : null;

    if (i == 0) nk::widget_disable_begin(ctx);

    if (nk::button_image(ctx, icons::get(UP))) {
        Layer prev = self.layers[i - 1];
        self.layers[i - 1] = layer;
        self.layers[i] = prev;
        self.selected_layer = -1;
    }

    if (i == 0) nk::widget_disable_end(ctx);
    if (i == self.layers.len() - 1) nk::widget_disable_begin(ctx);

    if (nk::button_image(ctx, icons::get(DOWN))) {
        Layer next= self.layers[i + 1];
        self.layers[i + 1] = layer;
        self.layers[i] = next;
        self.selected_layer = -1;
    }

    if (i == self.layers.len() - 1) nk::widget_disable_end(ctx);
    if (i == -1) nk::widget_disable_end(ctx);

    for (i = 0; i < self.layers.len();) {
        layer = self.layers[i];
        State *layer_state = layer.get_state();

        if (layer_state.prepare_for_deletion) {
            layer.free();
            self.layers.remove_at(i);
            continue;
        }

        /* if layer didn't get deleted */
        i++;
    }
}

fn void Manager.render(&self, void *loop, openpngstudio::Context *ctx)
{
    float start_x, start_y, end_x, end_y, rotation;

    Vector2 anchor = {rl::getScreenWidth() / 2.0f,
        rl::getScreenHeight() / 2.0f};

    foreach (i, layer : self.layers) {
        if (i == self.selected_layer) {
            Properties *props = layer.get_properties();

            end_x = props.image.width;
            end_y = props.image.height;

            start_x = anchor.x + props.offset.x;
            start_y = anchor.y + (-props.offset.y);

            start_x -= end_x / 2.0f;
            start_y -= end_y / 2.0f;

            start_x -= OUTLINE_WIDTH / 2.0f;
            end_x += OUTLINE_WIDTH;
            start_y -= OUTLINE_WIDTH / 2.0f;
            end_y += OUTLINE_WIDTH;
            rotation = props.rotation;
        }
        layer.draw(anchor);
    }

    if (self.selected_layer != -1) {
        Vector2[5] vertices = rotate({
            start_x + end_x / 2.0f, start_y + end_y / 2.0f, end_x, end_y
        }, rotation);

        rl::drawSplineLinear(&vertices, 5, OUTLINE_WIDTH, ctx.ambient);
    }

    self.animation_manager.tick();
}

fn void Manager.on_close(&self) @dynamic => self.selected_layer = -1;

fn Vector2[5] rotate(Rectangle dest, float rotation) @local
{
    Vector2 origin = { dest.width / 2.0f, dest.height / 2.0f };

    float sinRotation = math::sin(rotation * rl::DEG2RAD);
    float cosRotation = math::cos(rotation * rl::DEG2RAD);
    float x = dest.x;
    float y = dest.y;
    float dx = -origin.x;
    float dy = -origin.y;

    Vector2 topLeft = {};
    Vector2 topRight = {};
    Vector2 bottomLeft = {};
    Vector2 bottomRight = {};

    topLeft.x = x + dx*cosRotation - dy*sinRotation;
    topLeft.y = y + dx*sinRotation + dy*cosRotation;

    topRight.x = x + (dx + dest.width)*cosRotation - dy*sinRotation;
    topRight.y = y + (dx + dest.width)*sinRotation + dy*cosRotation;

    bottomLeft.x = x + dx*cosRotation - (dy + dest.height)*sinRotation;
    bottomLeft.y = y + dx*sinRotation + (dy + dest.height)*cosRotation;

    bottomRight.x = x + (dx + dest.width)*cosRotation - (dy + dest.height)*sinRotation;
    bottomRight.y = y + (dx + dest.width)*sinRotation + (dy + dest.height)*cosRotation;

    return {topLeft, topRight, bottomRight, bottomLeft, topLeft};
}
