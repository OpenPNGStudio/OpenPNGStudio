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
    List{PanelEntry} entries;
}

fn void Panel.init(&self, Allocator alloc)
{
    self.entries.init(alloc);
}

fn void Panel.free(&self)
{
    self.entries.free();
}

fn void Panel.add_entry(&self, PanelAction action, icons::Type icon, void *ctx)
{
    self.entries.push({
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
    
    if (nk::begin(ctx, "Panel", nk::rect(7, 7,
        (float) rl::getScreenWidth() - 14, 32), nk::WINDOW_NO_SCROLLBAR)) {

        nk::layout_row_template_begin(ctx, 32);
        for (int i = 0; i < self.entries.len(); i++) {
            nk::layout_row_template_push_static(ctx, 32);
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

        foreach (&entry : self.entries) {
            if (nk::button_image_styled(ctx, &btn, icons::get(entry.icon))) {
                entry.action(entry.ctx);
            }
        }
    }

    nk::end(ctx);
}
