#ifdef _WIN32
#include <raylib_win32.h>
#endif

#include <stdarg.h>
#include <stdio.h>
#include <time.h>
#include <uv.h>
#include <console.h>
#include <stdlib.h>
#include <stdbool.h>
#include <unistd.h>
#include <string.h>
#include <raylib-nuklear.h>

#define NLOGS 128

enum log_type {
    L_DEBUG,
    L_INFO,
    L_WARN,
    L_ERROR
};

struct log {
    enum log_type type;
    const char *fn;
    size_t line;
    char *buffer;
    struct log *next;
};

struct console {
    size_t log_count;
    bool show;
    struct log *logs;
    struct log *tail;
    struct nk_rect geometry;
};

static struct console c = {0};

static struct log *append_log();
static void free_list(struct log *log);

void console_init()
{
    c.geometry = nk_rect(0, 0, 0, 0);
}

void console_deinit()
{
    free_list(c.logs);
}

void console_show()
{
    c.show = true;
}

void console_draw(struct nk_context *ctx)
{
    if (c.geometry.x == 0 && c.geometry.y == 0 &&
        c.geometry.w == 0 && c.geometry.h == 0) {

        int width = GetScreenWidth();
        int height = GetScreenHeight();
        float w = width / 100.0f * 45.0f;
        float h = height / 100.0f * 45.0f;
        float x = 20;
        float y = height - 20 - h;

        c.geometry = nk_rect(x, y, w, h);
    }

    if (c.show) {
        if (nk_begin(ctx, "Debug Console", c.geometry,
                NK_WINDOW_TITLE | NK_WINDOW_CLOSABLE | NK_WINDOW_MOVABLE |
                NK_WINDOW_SCALABLE | NK_WINDOW_BORDER | NK_EDIT_NO_HORIZONTAL_SCROLL)) {

            nk_layout_row_begin(ctx, NK_DYNAMIC, 40, 4);
            nk_layout_row_push(ctx, 0.20f);
            nk_label(ctx, "Function", NK_TEXT_LEFT);
            nk_layout_row_push(ctx, 0.10f);
            nk_label(ctx, "Line", NK_TEXT_LEFT);
            nk_layout_row_push(ctx, 0.17f);
            nk_label(ctx, "Type", NK_TEXT_LEFT);
            nk_layout_row_push(ctx, 0.43f);
            nk_label(ctx, "Message", NK_TEXT_LEFT);
            nk_layout_row_end(ctx);

            nk_layout_row_dynamic(ctx, 2, 1);
            nk_rule_horizontal(ctx, ctx->style.window.border_color, false);

            struct log *iter = c.logs;

            while (iter != NULL) {
                nk_layout_row_begin(ctx, NK_DYNAMIC, 40, 4);
                nk_layout_row_push(ctx, 0.20f);
                nk_label_wrap(ctx, iter->fn);
                size_t size = snprintf(NULL, 0, "%ld", iter->line);
                char linebuff[size + 1];
                snprintf(linebuff, size + 1, "%ld", iter->line);
                nk_layout_row_push(ctx, 0.10f);
                nk_label_wrap(ctx, linebuff);

                struct nk_color old_color = ctx->style.text.color;

                nk_layout_row_push(ctx, 0.17f);

                switch (iter->type) {
                case L_DEBUG:
                    ctx->style.text.color = nk_rgb(0x0D, 0xBC, 0x79);
                    nk_label_wrap(ctx, "Debug");
                    break;
                case L_INFO:
                    ctx->style.text.color = nk_rgb(0x11, 0xA8, 0xCD);
                    nk_label_wrap(ctx, "Info");
                    break;
                case L_WARN:
                    ctx->style.text.color = nk_rgb(0xE5, 0xE5, 0x10);
                    nk_label_wrap(ctx, "Warning");
                    break;
                case L_ERROR:
                    ctx->style.text.color = nk_rgb(0xCD, 0x31, 0x31);
                    nk_label_wrap(ctx, "Error");
                    break;
                }

                ctx->style.text.color = old_color;

                nk_layout_row_push(ctx, 0.43f);
                nk_label_wrap(ctx, iter->buffer);

                nk_layout_row_end(ctx);
                iter = iter->next;
            }
        } else {
            struct nk_vec2 wprop = nk_window_get_position(ctx);
            c.geometry.x = wprop.x;
            c.geometry.y = wprop.y;

            wprop = nk_window_get_size(ctx);

            c.geometry.w = wprop.x;
            c.geometry.h = wprop.y;

            c.show = false;
        }

        nk_end(ctx);
    }
}

void console_debug(const char *fn, size_t line, const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    size_t bufsz = snprintf(NULL, 0, "%s:%lu \e[42;1m\e[37;1m D \e[0m ", fn, line);
    size_t add_sz = vsnprintf(NULL, 0, fmt, args);
    va_end(args);

    char final[bufsz + add_sz + 1];
    snprintf(final, bufsz + 1, "%s:%lu \e[42;1m\e[37;1m D \e[0m ", fn, line);

    va_start(args, fmt);
    snprintf(final + bufsz, add_sz + 1, fmt, args);
    va_end(args);

    printf("%s\n", final);

    struct log *l = append_log();
    l->type = L_DEBUG;
    l->fn = fn;
    l->line = line;
    l->buffer = malloc(add_sz + 1);
    memcpy(l->buffer, final + bufsz, add_sz + 1);
}

void console_info(const char *fn, size_t line, const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    size_t bufsz = snprintf(NULL, 0, "%s:%lu \e[46;1m\e[37;1m I \e[0m ", fn, line);
    size_t add_sz = vsnprintf(NULL, 0, fmt, args);
    va_end(args);

    char final[bufsz + add_sz + 1];
    snprintf(final, bufsz + 1, "%s:%lu \e[46;1m\e[37;1m I \e[0m ", fn, line);

    va_start(args, fmt);
    snprintf(final + bufsz, add_sz + 1, fmt, args);
    va_end(args);

    printf("%s\n", final);

    struct log *l = append_log();
    l->type = L_INFO;
    l->fn = fn;
    l->line = line;
    l->buffer = malloc(add_sz + 1);
    memcpy(l->buffer, final + bufsz, add_sz + 1);
}

void console_warn(const char *fn, size_t line, const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    size_t bufsz = snprintf(NULL, 0, "%s:%lu \e[43;1m\e[30;1m W \e[0m ", fn, line);
    size_t add_sz = vsnprintf(NULL, 0, fmt, args);
    va_end(args);

    char final[bufsz + add_sz + 1];
    snprintf(final, bufsz + 1, "%s:%lu \e[43;1m\e[30;1m W \e[0m ", fn, line);

    va_start(args, fmt);
    snprintf(final + bufsz, add_sz + 1, fmt, args);
    va_end(args);

    printf("%s\n", final);

    struct log *l = append_log();
    l->type = L_WARN;
    l->fn = fn;
    l->line = line;
    l->buffer = malloc(add_sz + 1);
    memcpy(l->buffer, final + bufsz, add_sz + 1);
}

void console_error(const char *fn, size_t line, const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    size_t bufsz = snprintf(NULL, 0, "%s:%lu \e[41;1m\e[30m E \e[0m ", fn, line);
    size_t add_sz = vsnprintf(NULL, 0, fmt, args);
    va_end(args);

    char final[bufsz + add_sz + 1];
    snprintf(final, bufsz + 1, "%s:%lu \e[41;1m\e[30m E \e[0m ", fn, line);

    va_start(args, fmt);
    snprintf(final + bufsz, add_sz + 1, fmt, args);
    va_end(args);

    printf("%s\n", final);

    struct log *l = append_log();
    l->type = L_ERROR;
    l->fn = fn;
    l->line = line;
    l->buffer = malloc(add_sz + 1);
    memcpy(l->buffer, final + bufsz, add_sz + 1);
}

static struct log *append_log()
{
    if (c.log_count == NLOGS) {
        struct log *prev = c.logs;
        c.logs = prev->next;
        c.log_count--;
        free(prev->buffer);
        free(prev);

        return append_log();
    }

    struct log *log = malloc(sizeof(*log));
    memset(log, 0, sizeof(*log));

    if (c.logs == NULL) {
        c.logs = log;
        c.tail = log;
        c.log_count = 0;
    } else {
        c.tail->next = log;
        c.tail = log;
    }

    c.log_count++;

    return log;
}

static void free_list(struct log *log)
{
    if (log == NULL)
        return;

    if (log->next)
        free_list(log->next);

    free(log->buffer);
    free(log);
}