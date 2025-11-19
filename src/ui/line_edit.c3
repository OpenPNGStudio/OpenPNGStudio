/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui::line_edit;

import nk;

struct LineEdit {
    char *buffer;
    int len;
    bool cleanup;
}

extern fn void line_edit_cleanup(LineEdit *edit);
extern fn void line_edit_draw(LineEdit *edit, nk::Context *ctx);
