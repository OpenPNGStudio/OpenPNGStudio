/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::layer::manager;

import std::core::mem;
import std::collections::list;
import openpngstudio::layer;
import openpngstudio::layer::static_layer;
import openpngstudio::layer::animated;
import openpngstudio::animation::manager;
import openpngstudio::ui;
import openpngstudio::core::icondb;
import openpngstudio::ui::line_edit;
import nk;
import raylib5::rl;

alias animation = module openpngstudio::animation::manager;

struct Manager {
    List{Layer} layers;
    animation::Manager *animation_manager;
    ui::Window config_win;
    isz selected_layer;
}

fn Manager *new_manager() @export("layer_manager_init")
{
    Manager *m = calloc(Manager.sizeof);
    m.layers.init(mem);
    m.selected_layer = -1;
    m.animation_manager = animation::new_manager();
    return m;
}

fn void Manager.add_layer(&self, StaticLayer *layer) @export("layer_manager_add_layer")
{
    Layer l;
    if (layer.props.is_animated) {
        l = (AnimatedLayer*) layer;
    } else {
        l = layer;
    }

    self.layers.push(l);
}

fn void Manager.ui(&self, nk::Context *ctx) @export("layer_manager_ui")
{
    if (self.config_win.ctx == null) {
        ui::window_init(&self.config_win, ctx, "Layer Configuration");
    }

    nk::Rect bounds = nk::window_get_content_region(ctx);
    bounds.h -= 45;
    nk::layout_row_dynamic(ctx, bounds.h, 1);
    bool res = nk::group_begin(ctx, "Layers", 0);

    foreach (i, layer : self.layers) {
        Properties *layer_props = layer.get_properties();

        if (i == self.selected_layer) {
            nk::layout_row_dynamic(ctx, 2, 1);
            nk::rule_horizontal(ctx, ctx.style.window.border_color, false);
        }

        nk::layout_row_template_begin(ctx, 30);
        nk::layout_row_template_push_static(ctx, 30);
        nk::layout_row_template_push_dynamic(ctx);
        nk::layout_row_template_push_static(ctx, 30);
        nk::layout_row_template_end(ctx);

        if (nk::button_image(ctx, icondb::get_icon(SELECT_ICON))) {
            if (self.selected_layer == -1) {
                self.selected_layer = i;
            } else {
                self.selected_layer = -1;
            }
        }

        line_edit::line_edit_draw(&layer_props.name, ctx);

        if (nk::button_image(ctx, icondb::get_icon(TRASH_ICON))) {
            State *layer_state = layer.get_state();
            layer_state.prepare_for_deletion = true;
            self.selected_layer = -1;
        }

        if (i == self.selected_layer) {
            nk::layout_row_dynamic(ctx, 2, 1);
            nk::rule_horizontal(ctx, ctx.style.window.border_color, false);
        }
    }

    if (res) nk::group_end(ctx);

    if (self.selected_layer == -1) nk::widget_disable_begin(ctx);

    nk::layout_row_template_begin(ctx, 30);
    nk::layout_row_template_push_static(ctx, 30);
    nk::layout_row_template_push_static(ctx, 30);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_end(ctx);

    isz i = self.selected_layer;
    Layer layer = i != -1 ? self.layers[i] : null;

    if (i == 0) nk::widget_disable_begin(ctx);

    if (nk::button_image(ctx, icondb::get_icon(UP_ICON))) {
        Layer prev = self.layers[i - 1];
        self.layers[i - 1] = layer;
        self.layers[i] = prev;
        self.selected_layer = -1;
    }

    if (i == 0) nk::widget_disable_end(ctx);
    if (i == self.layers.len() - 1) nk::widget_disable_begin(ctx);

    if (nk::button_image(ctx, icondb::get_icon(DOWN_ICON))) {
        Layer next= self.layers[i + 1];
        self.layers[i + 1] = layer;
        self.layers[i] = next;
        self.selected_layer = -1;
    }

    if (i == self.layers.len() - 1) nk::widget_disable_end(ctx);
    if (i == -1) nk::widget_disable_end(ctx);

    if (self.selected_layer != -1) self.config_win.show = true;

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

fn void Manager.draw(&self, void *loop) @export("layer_manager_render")
{
    Vector2 anchor = {rl::getScreenWidth() / 2.0f,
        rl::getScreenHeight() / 2.0f};

    foreach (layer : self.layers) {
        layer.draw(anchor);
    }

    self.animation_manager.tick();
}

fn void Manager.show_props(&self, nk::Context *ctx, bool *ui_focused) @export("draw_props")
{
    if (ui::window_begin(&self.config_win, nk::WINDOW_TITLE |
        nk::WINDOW_MOVABLE | nk::WINDOW_CLOSABLE | nk::WINDOW_BORDER |
        nk::WINDOW_MINIMIZABLE | nk::WINDOW_SCALABLE)) {
        *ui_focused = self.config_win.focus;

        Layer layer = self.layers[self.selected_layer];
        layer.configure(ctx);
        // self.animation_manager.animation_selector(layer, ctx);
    } else {
        self.selected_layer = -1;
    }

    if (self.config_win.state != HIDE) ui::window_end(&self.config_win);
}
