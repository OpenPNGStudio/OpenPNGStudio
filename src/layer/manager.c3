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
    LayerGroup root;
    Config conf;
    layer::Command selected;
}

const OUTLINE_WIDTH = 10.0f;

fn void Manager.init(&self, WindowManager *wm, Allocator alloc)
{
    self.root.init(alloc);
    self.conf.init();
    self.selected = { NONE, null, null };

    wm.register("Layer Manager", self);
    wm.register("Layer Configuration", &self.conf);
}

fn void Manager.add(&self, Layer layer) => self.root.add(layer);

fn void Manager.draw(&self, WindowManager *wm, nk::Context *ctx) @dynamic
{
    float win_width = nk::window_get_width(ctx);
    float min_width = math::max(win_width * 0.49f, 250.0f);

    nk::layout_row_template_begin(ctx, 30);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_static(ctx, 30);
    nk::layout_row_template_end(ctx);

    nk::label(ctx, "Model Settings", nk::TEXT_LEFT);
    if (nk::button_image(ctx, icons::get(CFG))) {
        self.conf.selected = &self.root;
        wm.show(&self.conf);
    }

    nk::Rect bounds = nk::window_get_content_region(ctx);
    bounds.h -= 40 * 2;

    nk::layout_row_dynamic(ctx, bounds.h, 1);
    bool res = nk::group_begin(ctx, "Layers", 0);

    nk::style_push_vec2(ctx, &ctx.style.window.padding, nk::vec2(0, 0));
    Flags old = ctx.current.flags;
    ctx.current.flags |= nk::WINDOW_NO_SCROLLBAR;

    layer::Command cmd;

    foreach (layer : self.root.layers) {
        layer::Command out = layer.layer_entry(ctx);
        if (cmd.type == NONE && out.type != NONE) {
            if (out.parent == null) out.parent = &self.root;
            cmd = out;
        }
    }

    if (cmd.type != NONE) {
        switch (cmd.type) {
        case CONFIG:
            self.conf.selected = cmd.layer;
            wm.show(&self.conf);
        case SELECT:
            if (self.selected.layer == cmd.layer) {
                self.selected = { NONE, null, null };
                break;
            }
            self.selected = cmd;
        case DELETE:
            if (self.selected.layer == cmd.layer) {
                self.selected = { NONE, null, null };
            }

            cmd.parent.del(cmd.layer);
        default:
            io::printn(cmd);
        }
    }

    ctx.current.flags = old;
    nk::style_pop_vec2(ctx);
    
    if (res) nk::group_end(ctx);

    nk::layout_row_template_begin(ctx, 30);
    nk::layout_row_template_push_static(ctx, 100);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_static(ctx, 30);
    nk::layout_row_template_push_static(ctx, 30);
    nk::layout_row_template_end(ctx);

    if (nk::button_label(ctx, "Add Group")) {
        LayerGroup *group = malloc(LayerGroup.sizeof);

        String name = "New Group";
        group.init(mem, name.zstr_copy(mem));
        group.parent = &self.root;

        self.root.add(group);
    }

    nk::spacer(ctx);

    if (nk::button_image(ctx, icons::get(UP)) && self.selected.type != NONE) {
        self.selected.parent.up(&self.selected);
    }

    if (nk::button_image(ctx, icons::get(DOWN)) && self.selected.type != NONE) {
        self.selected.parent.down(&self.selected);
    }
}

fn void Manager.render(&self)
{
    Origin origin = {
        .position = {
            rl::getScreenWidth() / 2.0f,
            rl::getScreenHeight() / 2.0f
        },
        .scale = {1, 1},
        .rotation = 0,
        .tint = { 0xFF, 0xFF, 0xFF, 0xFF }
    };

    foreach (layer : self.root.layers) {
        layer.draw(origin);
    }

    // float start_x, start_y, end_x, end_y, rotation;
    //
    // Vector2 anchor = {rl::getScreenWidth() / 2.0f,
    //     rl::getScreenHeight() / 2.0f};
    //
    // foreach (i, layer : self.layers) {
    //     if (i == self.selected_layer) {
    //         Properties *props = layer.get_properties();
    //
    //         end_x = props.image.width;
    //         end_y = props.image.height;
    //
    //         start_x = anchor.x + props.offset.x;
    //         start_y = anchor.y + (-props.offset.y);
    //
    //         start_x -= end_x / 2.0f;
    //         start_y -= end_y / 2.0f;
    //
    //         start_x -= OUTLINE_WIDTH / 2.0f;
    //         end_x += OUTLINE_WIDTH;
    //         start_y -= OUTLINE_WIDTH / 2.0f;
    //         end_y += OUTLINE_WIDTH;
    //         rotation = props.rotation;
    //     }
    //     layer.draw(anchor);
    // }
    //
    // if (self.selected_layer != -1) {
    //     Vector2[5] vertices = rotate({
    //         start_x + end_x / 2.0f, start_y + end_y / 2.0f, end_x, end_y
    //     }, rotation);
    //
    //     rl::drawSplineLinear(&vertices, 5, OUTLINE_WIDTH, ctx.ambient);
    // }
    //
    // // self.animation_manager.tick();
}

// fn void Manager.on_close(&self) @dynamic => self.selected_layer = -1;

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
