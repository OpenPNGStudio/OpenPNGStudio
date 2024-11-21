#ifndef _CONTEXT_H_
#define _CONTEXT_H_

#include "layermgr.h"
#include "messagebox.h"
#include <uv.h>
#include <filedialog.h>

enum fileload_state {
    NOTHING,
    LOADING_IMAGE,
};

struct file_loading {
    uv_fs_t close_req;
    uv_fs_t open_req;
    uv_fs_t read_req;
    uv_buf_t buffer;
    bool ready;
};

struct context {
    enum fileload_state loading_state;
    /* TODO: rename */
    struct file_loading f;

    uv_loop_t *loop;
    struct nk_context *ctx;
    struct filedialog dialog;
    float width, height;

    struct layer_manager mgr;
};

#endif