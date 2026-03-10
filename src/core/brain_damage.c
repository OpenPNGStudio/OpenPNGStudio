/* SPDX-License-Identifier: GPL-3.0-or-later */

/* Not really Microsoft to blame *pat pat*
 * 
 * Some C developers never heard the word "consistency"
 */
#include <raylib-nuklear.h>
#include <stdio.h>

nk_flags winabi_get_nk_flags(struct nk_context *ctx)
{
	return ctx->current->flags;
}

void winabi_add_nk_flag(struct nk_context* ctx, nk_flags flag)
{
	ctx->current->flags |= flag;
}

void winabi_set_nk_flag(struct nk_context* ctx, nk_flags flag)
{
	ctx->current->flags = flag;
}

static struct nk_vec2 winabi_panel_get_padding2(struct nk_style* style, enum nk_panel_type type)
{
    switch (type) {
    default:
    case NK_PANEL_WINDOW:
        return style->window.padding;
    case NK_PANEL_GROUP:
        return style->window.group_padding;
    case NK_PANEL_POPUP:
        return style->window.popup_padding;
    case NK_PANEL_CONTEXTUAL:
        return style->window.contextual_padding;
    case NK_PANEL_COMBO:
        return style->window.combo_padding;
    case NK_PANEL_MENU:
        return style->window.menu_padding;
    case NK_PANEL_TOOLTIP:
        return style->window.menu_padding;
    }

    return nk_vec2(0, 0);
}

struct nk_vec2 winabi_panel_get_padding(struct nk_context* ctx)
{
    return winabi_panel_get_padding2(&ctx->style, ctx->current->layout->type);
}

#ifdef _WIN32
uint16_t htons(uint16_t x)
{
    return (uint16_t)((x << 8) | (x >> 8));
}
#endif