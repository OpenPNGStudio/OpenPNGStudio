#pragma once

#include <context.h>
#include <editor.h>

struct model {
    struct context *ctx;
    struct editor *editor;
};

char *model_generate_manifest(struct model *model);
void model_write(struct model *model, const char *path);
void model_load(struct model *model, const char *path);
