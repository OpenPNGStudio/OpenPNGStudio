#pragma once

#include "layermgr.h"
#include "ui/window.h"

struct gif_configurator {
    struct window win;
    struct model_layer *layer;
    char **inputs;
    int *lengths;
    bool global_delay;
};

void gif_configurator_draw(struct gif_configurator *cfg,
    struct nk_context *ctx, bool *ui_focused);
