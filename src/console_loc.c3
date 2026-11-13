/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::console;

import std::io;
import std::os::env;

fn String? find_log()
{
    Path home = path::home_directory(tmem)!;

    Path dir2;
    $if env::WIN32:
        if (try String appdata = env::tget_var("LOCALAPPDATA") && appdata.len) {
            Path cache_dir = path::temp(appdata)!;
            dir2 = cache_dir.tappend("OpenPNGStudio")!;
        } else {
            dir2 = home.tappend("AppData\\Local\\OpenPNGStudio")!;
        }
    $else
        if (try String xdg_cache = env::tget_var("XDG_CACHE_HOME") && xdg_cache.len) {
            Path cache_dir = path::temp(xdg_cache)!;
            dir2 = cache_dir.tappend("OpenPNGStudio")!;
        } else {
            dir2 = home.tappend(".cache/OpenPNGStudio")!;
        }
    $endif

    (void) path::mkdir(dir2, true);
    return dir2.tappend("log.txt")!.str_view();
}
