/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui::messagebox;
import nk;
import raylib5::rl;

enum Type {
    INFO,
    WARN,
    ERROR,
    CUSTOM
}

alias CustomFn = fn int(MessageBox *box, nk::Context *ctx);

struct MessageBox {
    ZString title;
    ZString body;
    Type type;
    int res;
    CustomFn custom;
    void *userdata;
}

fn MessageBox info(ZString title, ZString body)
{
    return {
        .title = title,
        .body = body,
        .type = INFO,
        .res = -1,
        .custom = null,
.userdata = null,
    };
}

fn MessageBox warn(ZString title, ZString body)
{
    MessageBox box = info(title, body);
    box.type = WARN;

    return box;
}

fn MessageBox error(ZString title, ZString body)
{
    MessageBox box = info(title, body);
    box.type = ERROR;

    return box;
}

fn MessageBox custom(ZString title, CustomFn fun, void *userdata)
{
    MessageBox box = info(title, null);
    box.type = CUSTOM;
    box.custom = fun;
    box.userdata = userdata;

    return box;
}

fn void MessageBox.run(&self, nk::Context *ctx)
{
    if (self.res == -1) {
        nk::Rect bounds = nk::window_get_content_region(ctx);
        int extra_flags = 0;

        openpngstudio::Context *app_ctx = openpngstudio::get_ctx();
        Vector2 size = rl::measureTextEx(app_ctx.font, self.body, 16, 16 / 10.0f);
        size.x += 16;
        size.y += 16 + 50 + 30;

        float w = size.x;
        float h = size.y;

        w = max(w, 200);

        if (self.type == CUSTOM) {
            w = bounds.w / 100.0f * 80.0f;
            h = bounds.h / 100.0f * 80.0f;
        }

        float x = (bounds.w - w) / 2.0f;
        float y = (bounds.h - h) / 2.0f;

        if (self.type != CUSTOM) extra_flags |= nk::WINDOW_NO_SCROLLBAR;

        if (nk::popup_begin(ctx, nk::POPUP_STATIC, (CChar*) self.title,
            nk::WINDOW_TITLE | nk::WINDOW_CLOSABLE | nk::WINDOW_BORDER | 
            extra_flags, nk::rect(x, y, w, h))) {

            nk::Color text_color;
            switch (self.type) {
            case INFO:
                text_color = ctx.style.text.color;
            case WARN:
                text_color = nk::rgb(0xFF, 0xFF, 0x33);
            case ERROR:
                text_color = nk::rgb(0xFF, 0x33, 0x33);
            case CUSTOM:
                self.res = self.custom(self, ctx);

                if (self.res != -1) nk::popup_close(ctx);
                nk::popup_end(ctx);
                return;
            }

            bounds = nk::window_get_content_region(ctx);
            if (self.type != CUSTOM) {
                nk::layout_row_dynamic(ctx, bounds.h - 50.0f, 1);
                nk::label_colored_wrap(ctx, (CChar*) self.body, text_color);

                nk::layout_row_begin(ctx, nk::DYNAMIC, 30, 3);

                nk::layout_row_push(ctx, 0.1f);
                nk::spacing(ctx, 1);
                nk::layout_row_push(ctx, 0.35f);
                if (nk::button_label(ctx, "Ok")) {
                    self.res = 0;
                    nk::popup_close(ctx);
                }

                nk::layout_row_push(ctx, 0.1f);
                nk::spacing(ctx, 1);
                nk::layout_row_push(ctx, 0.35f);
                if (nk::button_label(ctx, "Cancel")) {
                    self.res = 1;
                    nk::popup_close(ctx);
                }
                nk::layout_row_push(ctx, 0.1f);
                nk::spacing(ctx, 1);
                nk::layout_row_end(ctx);
            }

            nk::popup_end(ctx);
        } else {
            self.res = 0;
        }
    }
}
