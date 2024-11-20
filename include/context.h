#ifndef _CONTEXT_H_
#define _CONTEXT_H_

#include "messagebox.h"
#include <uv.h>
#include <filedialog.h>

struct context {
    uv_loop_t *loop;
    struct nk_context *ctx;
    struct filedialog dialog;
    float width, height;
};

#endif