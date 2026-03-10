/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::layer::static_layer;

import std::collections::list;
import openpngstudio::image;
import openpngstudio::layer, openpngstudio::outline;
import openpngstudio::animation;
import openpngstudio::core::mask;
import openpngstudio::ui::line_edit;
import openpngstudio::ui::icons;
import ev;
import std::math;
import raylib5::rl;
import nk;
import opng;

struct StaticLayer (Layer) {
    LineEdit name;
    Vector2 position, scale;
    float rotation;
    rl::Color tint;
    usz timeout;
    image::Image* image;
    Mask mask;
    char[2] input_buffer;
    int input_length;
    List{AnimationEntry} animations;
    bitstruct : char {
        bool toggle;
        bool is_toggled;
        bool is_toggle_running;
        bool is_timeout_running;
        bool active;
    }
}

fn void StaticLayer.init(&self, Allocator alloc, ZString name,
    image::Image *img)
{
    if (name != null) {
        self.name.buffer = name;
        self.name.len = (int) name.len();
        self.name.cleanup = false;
    } else {
        self.name.buffer = null;
        self.name.cleanup = true;
        self.name.reinit();
    }
    self.position = {};
    self.scale = { 1, 1 };
    self.rotation = 0;
    self.tint = rl::WHITE;
    self.toggle = false;
    self.is_toggled = false;
    self.is_toggle_running = false;
    self.is_timeout_running = false;
    self.active = false;
    self.timeout = 0;
    self.image = img;
    self.mask = mask::DEFAULT;
    self.animations.init(alloc);
    self.input_length = 0;
}

fn void StaticLayer.free(&self) @dynamic
{
    free(self.name.buffer);
    if (self.image != null) self.image.free();
    self.animations.free();
}

fn bool StaticLayer.draw(&self, Origin origin) @dynamic => draw(self, origin);
fn layer::Command StaticLayer.layer_entry(&self, nk::Context *ctx) @dynamic => 
    entry(self, ctx);
fn void StaticLayer.config(&self, nk::Context *ctx) @dynamic => 
    config(self, ctx);
fn bool StaticLayer.can_cleanup(&self) @dynamic => !(self.is_toggle_running ||
    self.is_timeout_running);
fn void? StaticLayer.pack(&self, Writer *wr) @dynamic => pack(self, wr);

fn void? pack(StaticLayer *self, Writer *wr)
{
    SQLLayerData data = static_layer::prepare_data(self);

    uint layer_id = wr.add_layer_data(data)!;
    
    foreach (anim : self.animations) {
        unreachable("UNIMPLEMENTED");
        /*
        anim.layer_id = layer_id;
        wr.add_animation(anim)!;
        */
    }

    wr.add_layer({0, layer_id})!;
}

fn bool draw(StaticLayer *self, Origin origin)
{
    rl::Texture2D texture = self.image.texture;

    bool mask_test = mask::cmp(mask::get(), self.mask);

    if ((self.active || self.is_toggled) || mask_test) {
        rl::Vector2 orig_pos = origin.position;
        
        rl::Vector2 fixed_pos = { self.position.x, -self.position.y };
        rl::Vector2 scaled = rl::vector2Multiply(fixed_pos, origin.scale);
        rl::Vector2 rotated = rl::vector2Rotate(scaled, origin.rotation * 
            rl::DEG2RAD);

        origin.position = rl::vector2Add(origin.position, rotated);

        origin.scale = rl::vector2Add(origin.scale, {
            self.scale.x - 1, self.scale.y - 1
        });

        origin.rotation += self.rotation;
        origin.tint = self.tint;

        rl::drawLineEx(orig_pos, origin.position, 5, rl::LIME);

        foreach (&a : self.animations) {
            if (a.a == null) continue;

            BasicAnimation *b = a.a.get_base();
            b.enable(true);
            a.a.animate(&origin);
        }

        float scaled_width = texture.width * origin.scale.x;
        float scaled_height = texture.height * origin.scale.y;

        outline::draw_texture(texture, {
            .x = 0, .y = 0, .width = texture.width, .height = texture.height,
        }, {
            .x = origin.position.x,
            .y = origin.position.y,
            .width = scaled_width,
            .height = scaled_height,
        }, {
            .x = scaled_width / 2.0f, .y = scaled_height / 2.0f,
        }, origin.rotation, origin.tint);

        if (!self.toggle) {
            /* spawn live timeout */
            if (!self.active && self.timeout > 0 && !self.is_timeout_running) {
                if (self.mask != mask::DEFAULT) start_timeout(self);
            }
        } else {
            if (!self.is_toggle_running && mask_test) {
                if (self.mask != mask::DEFAULT) start_toggle(self);
            }
        }

        return true;
    }

    foreach (a : self.animations) {
        if (a.a == null) continue;

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

    layer::Command res;

    if (nk::button_image(ctx, icons::get(PICK))) {
        res = {
            SELECT,
            self,
            null
        };
    }

    self.name.draw(ctx);

    if (nk::button_image(ctx, icons::get(CFG))) {
        res = {
            CONFIG,
            self,
            null
        };
    }

    if (nk::button_image(ctx, icons::get(TRASH))) {
        res = {
            DELETE,
            self,
            null
        };
    }

    return res;
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

        nk::property_float(ctx, "#X:", float.min, &self.position.x,
            float.max, off, off);
        nk::property_float(ctx, "#Y:", float.min, &self.position.y,
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

    nk::label(ctx, "Scale: ", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Scale Group", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 2);

        float scale_off = holding_shift ? 0.1f : 0.01f;

        if (holding_shift) {
            self.scale.x = math::round_to_decimals(self.scale.x, 1);
            self.scale.y = math::round_to_decimals(self.scale.y, 1);
        }

        nk::property_float(ctx, "#X:", 0, &self.scale.x,
            float.max, scale_off, scale_off);
        nk::property_float(ctx, "#Y:", 0, &self.scale.y,
            float.max, scale_off, scale_off);

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

    int to_remove = -1;

    foreach (i, &a : self.animations) {
        if (a.config(ctx)) to_remove = (int) i;
    }

    if (to_remove != -1) self.animations.remove_at(to_remove);

    nk::layout_row_template_begin(ctx, 35);
    nk::layout_row_template_push_static(ctx, 125);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_end(ctx);

    if (nk::button_label(ctx, "Add Animation")) {
        self.animations.push({
            .a = null,
            .input_buffer = (char[2]) {0, 0},
            .input_length = 0,
            .selected_animation = 0,
            .selected_easing = 0,
            .custom_cfg_state = nk::MINIMIZED,
        });
    }

    nk::spacer(ctx);
}

fn SQLLayerData prepare_data(StaticLayer *self) => {
    self.name.buffer,
    {
        self.position.x,
        self.position.y
    },
    {
        self.scale.x,
        self.scale.y
    },
    self.rotation,
    color_to_uint(self.tint),
    self.timeout,
    self.image == null ? 0 : self.image.id,
    self.mask,
    self.toggle
};

fn uint color_to_uint(rl::Color color) @local
{
    uint res = 0;

    res |= ((uint) color.r) << 24;
    res |= ((uint) color.g) << 16;
    res |= ((uint) color.b) << 8;
    res |= color.a;

    return res;
}

alias LayerTimer = Timer{StaticLayer*};

import std::io;

fn void start_timeout(StaticLayer *self)
{
    Loop *loop = &openpngstudio::get_ctx().loop;
    self.active = true;
    self.is_timeout_running = true;

    LayerTimer *timer = mem::new(LayerTimer);
    timer.init(loop, self.timeout, self, fn (timer) {
        StaticLayer *self = timer.ctx;
        self.active = false;
        self.is_timeout_running = false;

        Loop *loop = &openpngstudio::get_ctx().loop;
        loop.submit_cleanup(timer, &free);

        return DISARM;
    });

    loop.add(timer);
}

fn void start_toggle(StaticLayer *self)
{
    Loop *loop = &openpngstudio::get_ctx().loop;

    self.is_toggled = !self.is_toggled;
    self.is_toggle_running = true;

    LayerTimer *timer = mem::new(LayerTimer);
    timer.init(loop, 250, self, fn (timer) {
        StaticLayer *self = timer.ctx;
        self.is_toggle_running = false;

        Loop *loop = &openpngstudio::get_ctx().loop;
        loop.submit_cleanup(timer, &free);

        return DISARM;
    });

    loop.add(timer);
}
