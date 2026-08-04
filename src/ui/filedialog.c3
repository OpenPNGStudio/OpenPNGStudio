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

fn FileDialog init_filedialog()
{
    $if env::LINUX:
        filedialogs::xdp::XdpFileDialog *xdp = filedialogs::xdp::init();
        if (xdp) return xdp;
    $endif
    
    log::warn("Unable to use native file dialog, using fallback");
    return filedialogs::builtin::init();
}
