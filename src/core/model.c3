/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::core::model;

import openpngstudio::ui;
import openpngstudio::layer;
import openpngstudio::animation;
import unuv;

struct Model {
    layer::Manager mgr;
    animation::Engine engine;
}


