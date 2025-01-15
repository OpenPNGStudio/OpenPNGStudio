#ifndef _EDITOR_H_
#define _EDITOR_H_

#include "microphone.h"
#include "ui/window.h"
#include <layermgr.h>
#include <raylib-nuklear.h>
#include <stdint.h>

enum editor_tab_id {
    OVERVIEW = 0,
    LAYERS = 1,
    MICROPHONE = 1,
    SCRIPTS = 2,
    SCENE = 2,
};

struct editor {
    /* TABS */
    struct layer_manager layer_manager;

    /* STATE */
    enum editor_tab_id current_tab;
    struct window win;
    struct microphone_data *mic;
    size_t previous_volume;
    size_t microphone_trigger;
    Color background_color;
    int timer_ttl;

    bool talk_timer_running;
    bool pause_timer_running;
};

void editor_draw(struct editor *editor, struct nk_context *ctx, bool *ui_focused);
void editor_draw_stream(struct editor *editor, struct nk_context *ctx,
    bool *ui_focused);
void editor_apply_mask(struct editor *editor);

#endif
