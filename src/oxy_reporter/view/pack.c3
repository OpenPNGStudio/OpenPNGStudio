module oxy_reporter::pack @if($feature(OXY_REPORTER_STANDALONE));

import std::io;
import std::os::env;
import std::core::string;
import std::compression::zip;
import std::time::datetime;

import openpngstudio::console;

import oxy_reporter;
import raylib5::rl;

ZString pretty_loc = "";
Path root_dir;

bool zip_ready = false;
ZipArchive archive;

struct Env {
    char[128] os;
    char[128] cpu;
    char[256] gpu;
    char[32] display;
}

extern fn void gather_env(Env *env);

fn Path find_location()
{
    bool at_home;
    TzDateTime now = datetime::now().to_local();

    String name = string::format(tmem, "OPNG-crash-%04d%02d%02d-%02d%02d.zip",
        now.year, now.month.ordinal + 1, now.day, now.hour, now.min);

    Path root;
    if (try Path downloads = path::downloads_directory(tmem)) root = downloads;

    $if env::POSIX:
        String home = env::tget_var("HOME")!!;
        Path home_path = path::temp(home)!!;
        Path downloads = home_path.tappend("Downloads")!!;

        if (path::exists(downloads)) {
            root = downloads;
        } else {
            root = path::temp(home)!!;
            at_home = true;
        }
    $else
        abort("How did you get here?");
    $endif

    Path parent = root;
    if (!at_home) parent = root.parent()!!;

    pretty_loc = string::tformat("~%s/%s", root.str_view()[parent.str_view().len..], name).zstr_copy(mem);

    root_dir = path::new(mem, root.str_view())!!;

    return root.append(mem, name)!!;
}

fn GuiState draw(Texture2D icon, File crash_dump)
{
    rl::drawTextureEx(icon, { 10, -10 }, 0, 1, rl::WHITE);

    draw_text("OpenPNGStudio crashed", 145, 24, 26, rl::WHITE);
    draw_text("Creating crash report for you.", 145, 60, 18, rl::WHITE);

    if (!zip_ready) {
        archive = zip::open(mem, find_location().str_view(), "w")!!;
        zip_ready = true;
    } else if (crash::crash_info) {
        $if env::FREEBSD:
            ZipEntryWriter wr = archive.open_writer("OpenPNGStudio.core")!!;
        $else
            ZipEntryWriter wr = archive.open_writer("OpenPNGStudio.dmp")!!;
        $endif

        io::copy_to(&crash_dump, &wr)!!;
        wr.close()!!;

        crash::crash_info = false;
    } else if (crash::application_log) {
        if (try String loc = console::find_log()) {
            File f = file::open(loc, "r")!!;
            defer (void) f.close();

            ZipEntryWriter wr = archive.open_writer("log.txt")!!;
            io::copy_to(&f, &wr)!!;
            wr.close()!!;
        }

        crash::application_log = false;
    } else if (crash::system_env) {
        Env env;
        gather_env(&env);

        ZipEntryWriter wr = archive.open_writer("env.txt")!!;

        io::fprintf(&wr, "--- System Environment ---\n")!!;
        io::fprintf(&wr, "OS:             %s\n", (ZString) &env.os)!!;
        io::fprintf(&wr, "CPU:            %s\n", (ZString) &env.cpu)!!;
        io::fprintf(&wr, "GPU:            %s\n", (ZString) &env.gpu)!!;
        io::fprintf(&wr, "Display Server: %s\n", (ZString) &env.display)!!;

        wr.close()!!;

        crash::system_env = false;
    } else {
        if (crash::str.len() > 0) {
            ZipEntryWriter wr = archive.open_writer("note.txt")!!;

            io::fprintn(&wr, crash::str.str_view())!!;
            wr.close()!!;
        }

        archive.close()!!;
        return REPORT_SCREEN;
    }

    return PACK;
}

