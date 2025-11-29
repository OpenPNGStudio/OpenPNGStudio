/* SPDX-License-Identifier: GPL-3.0-or-later */
#pragma once
#include <core/icon_db.h>
#include <raylib-nuklear.h>

struct panel;

struct panel *panel_new();
void panel_add_entry(struct panel *self, void (*action)(void* ctx),
    enum icon_type type, void *ctx);
void panel_ui(struct panel *panel, struct nk_context *ctx);
