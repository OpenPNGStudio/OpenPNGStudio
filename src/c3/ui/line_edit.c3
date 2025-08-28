/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui::line_edit;

struct LineEdit {
    char *buffer;
    int len;
    bool cleanup;
}
