/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::layer::static_layer;

import std::collections::list;
import openpngstudio::image;
import openpngstudio::layer;
import openpngstudio::animation;
import openpngstudio::core::mask;
import openpngstudio::ui::line_edit;
import openpngstudio::ui::icons;
import std::math;
import raylib5::rl;
import nk;

struct StaticLayer (Layer) {
    LineEdit name;
    Vector2 position, scale;
    float rotation;
    rl::Color tint;
    usz timeout;
    image::Image* image;
    Mask mask;
    List{AnimationEntry} animations;
    char[2] input_buffer;
    int input_length;
    bitstruct : char {
        bool toggle;
        bool is_toggled;
        bool is_toggle_running;
        bool active;
    }
}

fn void StaticLayer.init(&self, Allocator alloc, image::Image *img)
{
    self.name.cleanup = true;
    self.name.reinit();
    self.position = {};
    self.scale = {};
    self.rotation = 0;
    self.tint = rl::WHITE;
    self.toggle = false;
    self.is_toggled = false;
    self.is_toggle_running = false;
    self.active = false;
    self.timeout = 0;
    self.image = img;
    self.mask = mask::DEFAULT;
    self.animations.init(alloc);
}

fn void StaticLayer.free(&self) @dynamic
{
    free(self.name.buffer);
    self.animations.free();
    // TODO: Image cleanup
}

fn bool StaticLayer.draw(&self, Origin origin) @dynamic => draw(self, origin);
fn layer::Command StaticLayer.layer_entry(&self, nk::Context *ctx) @dynamic => 
    entry(self, ctx);
fn void StaticLayer.config(&self, nk::Context *ctx) @dynamic => 
    config(self, ctx);

fn bool draw(StaticLayer *self, Origin origin)
{
    rl::Texture2D texture = self.image.texture;

    bool mask_test = mask::cmp(mask::get(), self.mask);

    if ((self.active || self.is_toggled) || mask_test) {
        origin.position.x += self.position.x;
        origin.position.y += -self.position.y;

        origin.scale.x += self.scale.x;
        origin.scale.y += self.scale.y;

        origin.rotation += self.rotation;

        origin.tint = self.tint;

        foreach (&a : self.animations) {
            BasicAnimation *b = a.a.get_base();
            b.enable(true);
            a.a.animate(&origin);
        }

        rl::drawTexturePro(texture, {
            .x = 0, .y = 0, .width = texture.width, .height = texture.height,
        }, {
            .x = origin.position.x,
            .y = origin.position.y,
            .width = texture.width, .height = texture.height,
        }, {
            .x = texture.width / 2.0f, .y = texture.height / 2.0f,
        }, origin.rotation, origin.tint);

        if (!self.toggle) {
            /* spawn live timeout */
            if (!self.active && self.timeout > 0) {
                // TODO: start timeout 
            }
        } else {
            if (!self.is_toggle_running && mask_test) {
                // TODO: start toggle
            }
        }

        return true;
    }

    foreach (a : self.animations) {
        BasicAnimation *b = a.a.get_base();
        b.enable(false);
    }

    return false;
}

fn layer::Command entry(StaticLayer *self, nk::Context *ctx)
{
    nk::layout_row_template_begin(ctx, 30);
    nk::layout_row_template_push_static(ctx, 30);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_static(ctx, 30);
    nk::layout_row_template_push_static(ctx, 30);
    nk::layout_row_template_end(ctx);

    if (nk::button_image(ctx, icons::get(PICK))) {
        return {
            SELECT,
            self,
            null
        };
    }

    self.name.draw(ctx);

    if (nk::button_image(ctx, icons::get(CFG))) {
        return {
            CONFIG,
            self,
            null
        };
    }

    if (nk::button_image(ctx, icons::get(TRASH))) {
        return {
            DELETE,
            self,
            null
        };
    }

    return {
        NONE,
        null,
        null,
    };
}

fn void config(StaticLayer *self, nk::Context *ctx)
{
    bool holding_shift = nk::input_is_key_down(&ctx.input, nk::KEY_SHIFT);
    float win_width = nk::window_get_width(ctx);
    float min_width = math::max(win_width * 0.49f, 250.0f);
    float off = holding_shift ? 1.0f : 0.1f;

    nk::layout_row_template_begin(ctx, 35);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_variable(ctx, min_width);
    nk::layout_row_template_end(ctx);

    nk::label(ctx, "Position: ", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Position Group", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 2);

        if (holding_shift) {
            self.position.x = math::round(self.position.x);
            self.position.y = math::round(self.position.y);
        }

        nk::property_float(ctx, "X:", float.min, &self.position.x,
            float.max, off, off);
        nk::property_float(ctx, "Y:", float.min, &self.position.y,
            float.max, off, off);

        nk::group_end(ctx);
    }

    nk::label(ctx, "Rotation:", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Rotation Group", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);

        if (holding_shift) {
            self.rotation = math::round(self.rotation);
        }

        nk::property_float(ctx, "##Rotation Angle", float.min,
            &self.rotation, float.max, off, off);

        nk::group_end(ctx);
    }

    nk::label(ctx, "Toggle mode:", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Toggle Mode Goup", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_template_begin(ctx, 30);
        nk::layout_row_template_push_dynamic(ctx);
        nk::layout_row_template_push_static(ctx, 75);
        nk::layout_row_template_end(ctx);

        nk::spacing(ctx, 1);
        bool has_toggle = self.toggle;
        nk::checkbox_label(ctx, "Enable", &has_toggle);
        self.toggle = has_toggle;

        nk::group_end(ctx);
    }

    nk::label(ctx, "Timeout (ms):", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Timeout Group", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);

        if (self.toggle) nk::widget_disable_begin(ctx);

        nk::property_int(ctx, "##Timeout", 0, (CInt*) &self.timeout, int.max, 1, 1);

        if (self.toggle) nk::widget_disable_end(ctx);

        nk::group_end(ctx);
    }

    nk::layout_row_dynamic(ctx, 4, 1);
    nk::spacer(ctx);
    nk::layout_row_dynamic(ctx, 2, 1);
    nk::rule_horizontal(ctx, ctx.style.window.border_color, false);
    nk::layout_row_dynamic(ctx, 4, 1);
    nk::spacer(ctx);

    mask::configure(&self.mask, &self.input_buffer,
        &self.input_length, ctx, "self activation: ");

    nk::layout_row_dynamic(ctx, 4, 1);
    nk::spacer(ctx);
    nk::layout_row_dynamic(ctx, 2, 1);
    nk::rule_horizontal(ctx, ctx.style.window.border_color, false);
    nk::layout_row_dynamic(ctx, 4, 1);
    nk::spacer(ctx);

    foreach (&a : self.animations) {
        a.config(ctx);
    }
}
