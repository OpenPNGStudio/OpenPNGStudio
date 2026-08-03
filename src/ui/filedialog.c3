/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui;

import std::net::url;

interface FileDialog {
    fn void open(ZString title, bool multiple);
    fn void save(ZString title);
    fn void set_filter(ZString[] extensions);
    fn bool ready();
    fn Url[] uris();
}
