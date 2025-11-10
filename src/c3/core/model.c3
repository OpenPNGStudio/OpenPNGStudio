/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::core::model;

import openpngstudio::ui;

struct Model {
    void *scheduler;
    void *mic;
    Editor *editor;
}