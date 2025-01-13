#ifndef _LINE_EDIT_H_
#define _LINE_EDIT_H_

#include <raylib-nuklear.h>
#include <stdbool.h>

struct line_edit {
    char *buffer;
    int len;
    bool cleanup;
};

void line_edit_cleanup(struct line_edit *edit);
void line_edit_draw(struct line_edit *edit, struct nk_context *ctx);

#endif
