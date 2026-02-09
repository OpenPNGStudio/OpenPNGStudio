/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui;

import openpngstudio::ui::icons;
import nk;
import std::math;

macro combo_begin(nk::Context *ctx, CChar *label, nk::Vec2 size) =>
    nk::combo_begin_image_label(ctx, label,
        &&(nk::Image[2]){icons::get(COMBO_OPEN), icons::get(COMBO)},
        size);

fn nk::Vec2 panel_get_padding(nk::Style *style, nk::PanelType type) @local
{
    switch (type) {
    default:
    case nk::PANEL_WINDOW: 
        return style.window.padding;
    case nk::PANEL_GROUP:
        return style.window.group_padding;
    case nk::PANEL_POPUP: 
        return style.window.popup_padding;
    case nk::PANEL_CONTEXTUAL: 
        return style.window.contextual_padding;
    case nk::PANEL_COMBO: 
        return style.window.combo_padding;
    case nk::PANEL_MENU:
        return style.window.menu_padding;
    case nk::PANEL_TOOLTIP: 
        return style.window.menu_padding;
    }
}

fn int combo(nk::Context *ctx, CChar **items, int count,
    int selected, int item_height, nk::Vec2 size)
{
    int i = 0;
    int max_height;
    nk::Vec2 item_spacing;
    nk::Vec2 window_padding;

    if (!ctx || !items ||!count) return selected;

    item_spacing = ctx.style.window.spacing;
    window_padding = panel_get_padding(&ctx.style, ctx.current.layout.type);

    max_height = count * item_height + count * (int) item_spacing.y;
    max_height += (int) item_spacing.y * 2 + (int) window_padding.y * 2;
    size.y = math::min(size.y, (float) max_height);

    if (combo_begin(ctx, items[selected], size)) {
        nk::layout_row_dynamic(ctx, (float) item_height, 1);
        for (i = 0; i < count; ++i) {
            if (nk::combo_item_label(ctx, items[i], nk::TEXT_LEFT)) {
                selected = i;
            }
        }
        nk::combo_end(ctx);
    }

    return selected;
}
