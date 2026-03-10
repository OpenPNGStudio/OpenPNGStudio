/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui;

import openpngstudio::ui::icons;
import std::collections::list;
import std::core::mem;
import nk;
import raylib5::rl;

alias Action = fn void(void *ctx);

enum Orientation {
    HORIZONTAL,
    VERTICAL
}

struct Entry {
    Action action;
    icons::Type icon;
    void *ctx;
}

struct Panel {
    Orientation direction;
    List{Entry}[2] left_entries;
    List{Entry}[2] right_entries;
}

fn void Panel.init(&self, Allocator alloc, Orientation direction)
{
    self.direction = direction;
    
    self.left_entries[0].init(alloc);
    self.right_entries[0].init(alloc);

    self.left_entries[1].init(alloc);
    self.right_entries[1].init(alloc);
}

fn void Panel.free(&self)
{
    self.left_entries[0].free();
    self.right_entries[0].free();

    self.left_entries[1].free();
    self.right_entries[1].free();
}

fn void Panel.add_left_entry(&self, Action action, icons::Type icon,
    void *ctx)
{
    openpngstudio::Context *app_ctx = openpngstudio::get_ctx();
    usz idx = app_ctx.editing ? 0 : 1;

    self.left_entries[idx].push({
        .action = action,
        .icon = icon,
        .ctx = ctx
    });
}

fn void Panel.add_right_entry(&self, Action action, icons::Type icon,
    void *ctx)
{
    openpngstudio::Context *app_ctx = openpngstudio::get_ctx();
    usz idx = app_ctx.editing ? 0 : 1;

    self.right_entries[idx].push({
        .action = action,
        .icon = icon,
        .ctx = ctx
    });
}

fn void Panel.ui(&self, nk::Context *ctx)
{
    nk::style_push_float(ctx, &ctx.style.window.rounding, 5.0f);
    defer nk::style_pop_float(ctx);

    nk::style_push_vec2(ctx, &ctx.style.window.padding, nk::vec2(0, 0));
    defer nk::style_pop_vec2(ctx);

    switch (self.direction) {
    case HORIZONTAL:
        if (nk::begin(ctx, "Panel", nk::rect(7, 7,
            (float) rl::getScreenWidth() - 14, 34), nk::WINDOW_NO_SCROLLBAR)) {
            horizontal(self, ctx);
        }
    case VERTICAL:
        if (nk::begin(ctx, "Panel", nk::rect(7, 7,
            34, (float) rl::getScreenHeight() - 14), nk::WINDOW_NO_SCROLLBAR)) {
            vertical(self, ctx);
        }
    }

    nk::end(ctx);
}

fn void horizontal(Panel *self, nk::Context *ctx) @local
{
    openpngstudio::Context *app_ctx = openpngstudio::get_ctx();
    usz idx = app_ctx.editing ? 0 : 1;
    
    nk::layout_row_template_begin(ctx, 34);
    for (int i = 0; i < self.left_entries[idx].len(); i++) {
        nk::layout_row_template_push_static(ctx, 34);
    }
    nk::layout_row_template_push_dynamic(ctx);
    for (int i = 0; i < self.right_entries[idx].len(); i++) {
        nk::layout_row_template_push_static(ctx, 34);
    }
    nk::layout_row_template_end(ctx);

    nk::StyleButton btn = ctx.style.button;
    btn.normal = {
        .type = nk::STYLE_ITEM_COLOR,
        .data = {
            .color = nk::rgba(0, 0, 0, 0),
        }
    };
    btn.active = btn.normal;
    btn.hover = btn.normal;

    foreach (&entry : self.left_entries[idx]) {
        bool layer_op = entry.icon == OPEN || entry.icon == SAVE || 
            entry.icon == LAYERS;

        nk::Image icon = icons::get(entry.icon);

        if (layer_op && app_ctx.file_lock) {
            btn.color_factor_background = 0.7f;
        }
        
        if (nk::button_image_styled(ctx, &btn, icon)) {
            if (!(layer_op && app_ctx.file_lock)) {
                entry.action(entry.ctx);
            }
        }

        if (layer_op && app_ctx.file_lock) {
            btn.color_factor_background = 1f;
        }
    }
    nk::spacer(ctx);
    foreach (&entry : self.right_entries[idx]) {
        if (nk::button_image_styled(ctx, &btn, icons::get(entry.icon))) {
            entry.action(entry.ctx);
        }
    }
}

fn void vertical(Panel *self, nk::Context *ctx) @local
{
    openpngstudio::Context *app_ctx = openpngstudio::get_ctx();
    usz idx = app_ctx.editing ? 0 : 1;

    nk::StyleButton btn = ctx.style.button;
    btn.normal = {
        .type = nk::STYLE_ITEM_COLOR,
        .data = {
            .color = nk::rgba(0, 0, 0, 0),
        }
    };
    
    btn.active = btn.normal;
    btn.hover = btn.normal;

    nk::Rect bounds = nk::window_get_bounds(ctx);
    nk::layout_row_dynamic(ctx, 34, 1);

    foreach (&entry : self.left_entries[idx]) {
        bool layer_op = entry.icon == OPEN || entry.icon == SAVE || 
            entry.icon == LAYERS;

        nk::Image icon = icons::get(entry.icon);

        if (layer_op && app_ctx.file_lock) {
            btn.color_factor_background = 0.7f;
        }
        
        if (nk::button_image_styled(ctx, &btn, icon)) {
            if (!(layer_op && app_ctx.file_lock)) {
                entry.action(entry.ctx);
            }
        }

        if (layer_op && app_ctx.file_lock) {
            btn.color_factor_background = 1f;
        }
    }

    usz total_count = self.left_entries[idx].len() + 
        self.right_entries[idx].len();

    float total_spacing = ctx.style.window.spacing.y * total_count;

    float height = bounds.h - (total_count * 34.0f) - total_spacing;

    nk::layout_row_dynamic(ctx, height, 1);
    nk::spacer(ctx);
    
    nk::layout_row_dynamic(ctx, 34, 1);
    
    foreach (&entry : self.right_entries[idx]) {
        if (nk::button_image_styled(ctx, &btn, icons::get(entry.icon))) {
            entry.action(entry.ctx);
        }
    }
}
