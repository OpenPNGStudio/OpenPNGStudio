module oxy_reporter @if($feature(OXY_REPORTER_STANDALONE));

import std::io;

fn void main(String[] args)
{
    File f = file::open("log.txt", "w")!!;
    defer (void) f.close();
    io::fprintn(&f, args)!!;
}