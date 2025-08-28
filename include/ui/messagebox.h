/* SPDX-License-Identifier: GPL-3.0-or-later */

#ifndef _MESSAGEBOX_H_
#define _MESSAGEBOX_H_

#include <raylib-nuklear.h>

enum messagebox_type {
    MESSAGEBOX_INFO,
    MESSAGEBOX_WARN,
    MESSAGEBOX_ERROR,
    MESSAGEBOX_CUSTOM,
};

struct messagebox {
    const char *title;
    const char *body;
    enum messagebox_type type;
    int res;
    int (*custom)(struct nk_context *ctx, struct messagebox *box);
    void *userdata;
};

struct messagebox messagebox_info(const char *title, const char *body);
struct messagebox messagebox_warn(const char *title, const char *body);
struct messagebox messagebox_error(const char *title, const char *body);
struct messagebox messagebox_custom(const char *title,
    int (*fn)(struct nk_context *ctx, struct messagebox *box),
    void* userdata);

void messagebox_run(struct messagebox *messagebox, struct nk_context *ctx);

#endif
