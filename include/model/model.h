#pragma once

#include <editor.h>
#include <work/scheduler.h>

struct model {
    struct work_scheduler *scheduler;
    struct editor *editor;
};

char *model_generate_manifest(struct model *model);
void model_write(struct model *model, const char *path);
void model_load(struct model *model, const char *path);
