module oxy_reporter @if($feature(OXY_REPORTER_STANDALONE));

import std::io;

fn void main(String[] args)
{
    File f = file::open("log.txt", "w")!!;
    defer (void) f.close();
    io::fprintn(&f, args)!!;
}

module oxy_reporter @if($feature(OXY_REPORTER_STANDALONE) && env::WIN32);

import std::core::main_stub;

fn int win_main(void *handle, void *prev_handle, Char16 *cmd_line, int show_cmd) @export("WinMain")
{
    return main_stub::@win_main_args(main, handle, prev_handle, cmd_line, show_cmd);
}

fn int win_main_cli(int argc, char **argv) @export("main")
{
    return main_stub::@main_args(main, argc, argv);
}