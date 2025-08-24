#pragma once

#include <c3.h>
#include <layer/layer.h>
#include <stdint.h>

typedef void animation_manager; /* struct */
typedef c3any_t animation; /* interface */
typedef c3any_t spinner; /* interface */

animation_manager *animation_manager_new();
void animation_manager_tick(animation_manager *self);
void animation_manager_add(animation_manager *self, struct layer *layer,
    animation anim);
void animation_manager_selector(animation_manager *self, struct layer *layer,
    struct nk_context *ctx);

spinner spinner_new(float rotation, uint64_t delay);
