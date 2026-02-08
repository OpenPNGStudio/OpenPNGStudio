/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui;

import openpngstudio::ui::icons;
import std::collections::list;
import std::core::mem;
import nk;
import raylib5::rl;

alias PanelAction = fn void(void *ctx);

struct PanelEntry {
    PanelAction action;
    icons::Type icon;
    void *ctx;
}

struct Panel {
    List{PanelEntry}[2] left_entries;
    List{PanelEntry}[2] right_entries;
}

fn void Panel.init(&self, Allocator alloc)
{
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

fn void Panel.add_left_entry(&self, PanelAction action, icons::Type icon,
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

fn void Panel.add_right_entry(&self, PanelAction action, icons::Type icon,
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
    openpngstudio::Context *app_ctx = openpngstudio::get_ctx();
    usz idx = app_ctx.editing ? 0 : 1;

    nk::style_push_float(ctx, &ctx.style.window.rounding, 5.0f);
    defer nk::style_pop_float(ctx);

    nk::style_push_vec2(ctx, &ctx.style.window.padding, nk::vec2(0, 0));
    defer nk::style_pop_vec2(ctx);
    
    if (nk::begin(ctx, "Panel", nk::rect(7, 7,
        (float) rl::getScreenWidth() - 14, 34), nk::WINDOW_NO_SCROLLBAR)) {

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
            if (nk::button_image_styled(ctx, &btn, icons::get(entry.icon))) {
                entry.action(entry.ctx);
            }
        }
        nk::spacer(ctx);
        foreach (&entry : self.right_entries[idx]) {
            if (nk::button_image_styled(ctx, &btn, icons::get(entry.icon))) {
                entry.action(entry.ctx);
            }
        }
    }

    nk::end(ctx);
}
