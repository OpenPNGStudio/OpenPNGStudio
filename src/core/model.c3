/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::core::model;

import openpngstudio::ui;
import openpngstudio::layer;
import unuv;

struct Model {
    layer::Manager mgr;
}

fn void write(Model *model, ZString path) @export("model_write")
{
}

fn void load(unuv::UnLoop *loop, Model *model, ZString path) @export("model_load")
{
}
