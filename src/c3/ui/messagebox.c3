/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui::messagebox;
import nk;

enum Type {
    INFO,
    WARN,
    ERROR,
    CUSTOM
}

alias CustomFn = fn int(nk::Context *ctx, MessageBox *box);

struct MessageBox {
    char *title;
    char *body;
    Type type;
    int res;
    CustomFn *custom;
    void *userdata;
}

extern fn MessageBox info(char *title, char *body) @extern("messagebox_info");
extern fn MessageBox warn(char *title, char *body) @extern("messagebox_warn");
extern fn MessageBox error(char *title, char *body) @extern("messagebox_error");

extern fn void run(MessageBox *box, nk::Context *ctx) @extern("messagebox_run");
