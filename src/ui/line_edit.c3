/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui::line_edit;

import nk;

struct LineEdit {
    ZString buffer;
    int len;
    bool cleanup;
}

fn void LineEdit.reinit(&self)
{
    if (self.cleanup) {
        if (self.buffer != null) free(self.buffer);
        self.cleanup = false;
        self.buffer = (ZString) malloc(1);
        self.buffer[0] = 0;
        self.len = 0;
    }
}

fn void LineEdit.draw(&self, nk::Context *ctx)
{
    self.reinit();

    int new_len = self.len;

    nk::edit_string(ctx, nk::EDIT_FIELD, (CChar*) self.buffer, &new_len, 
        self.len + 2, &nk::filter_default);

    if (new_len > self.len) {
        self.buffer = (ZString) realloc(self.buffer, (usz) ++self.len + 1);
        self.buffer[self.len] = 0;
    } else if (new_len < self.len) {
        self.buffer[new_len] = 0;
        self.len--;
    }
}
