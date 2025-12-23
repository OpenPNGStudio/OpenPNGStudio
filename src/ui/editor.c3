/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui;

import openpngstudio::layer;
import openpngstudio::ui::window;

import raylib5::rl;

enum EditorTabId : const int {
	OVERVIEW = 0,
	LAYERS = 1,
	MICROPHONE = 1,
	SCRIPTS = 2,
	SCENE = 2,
}

struct Editor {
	layer::Manager *layer_manager;
	EditorTabId current_tab;
	window::Window win;

	void *mic;
	usz previous_volume;
    usz microphone_trigger;
    rl::Color background_color;
    char[7] bg_color_in;
    int bg_color_len;
    int timer_ttl;

    bool talk_timer_running;
    bool pause_timer_running;
}
