#include <stddef.h>
#include <line_edit.h>
#include <stdlib.h>

void line_edit_draw(struct line_edit *edit, struct nk_context *ctx)
{
    if (edit->cleanup) {
        if (edit->buffer != NULL) {
            free(edit->buffer);
        }
        edit->cleanup = false;
        edit->buffer = malloc(1);
        *edit->buffer = 0;
        edit->len = 0;
    }

    int new_len = edit->len;

    nk_edit_string(ctx, NK_EDIT_SIMPLE, edit->buffer, &new_len, edit->len + 2, nk_filter_default);

    if (new_len > edit->len) {
        edit->buffer = realloc(edit->buffer, ++edit->len + 1);
        edit->buffer[edit->len] = 0;
    } else if (new_len < edit->len) {
        edit->buffer[new_len] = 0;
        edit->len--;
    }
}