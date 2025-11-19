/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng::list @if($feature(OPNG_STANDALONE));

import std::io, std::os;

fn int _main(int argc, ZString *argv)
{
    ichar c;

    while ((c = (ichar) getopt(argc, argv, "h")) != -1) {
        switch (c) {
        case 'h':
        default:
            usage();
        }
    }

    return 0;
}

fn void usage() @local
{
    io::fprintf(io::stderr(), "usage: opng list [-h] file\n")!!;
    os::exit(1);
}
