/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng @if($feature(OPNG_STANDALONE));

import std::io, std::os;

import opng::info, opng::pack, opng::dump;

alias OpngCmdFn = fn int(int argc, ZString *argv);
alias OpngCmdUsageFn = fn void();

struct OpngCmd {
    ZString name;
    OpngCmdFn func;
}

extern char *optarg @builtin;
extern int optind @builtin;
extern fn int getopt(int argc, char** argv, char *optstring) @builtin;

OpngCmd[] cmds @local = {
    {"info", &info::_main },
    {"pack", &pack::_main },
    {"dump", &dump::_main}
};

fn int main(int argc, ZString *argv)
{
    if (argc == 1) usage(false);

    ichar c;

    while ((c = (ichar) getopt(argc, argv, "+hV")) != -1) {
        switch (c) {
        case 'V':
            io::printfn("opng %s", env::PROJECT_VERSION);
            return 0;
        case 'h':
            usage(true);
        default:
            usage(false);
        }
    }

    argc -= optind;
    argv += optind;

    optind = 1;

    foreach (cmd : cmds) { 
        if (cmd.name == argv[0]) {
            return cmd.func(argc, argv);
        }
    }

    io::fprintfn(io::stderr(), "opng: invalid command: %s", argv[0])!!;

    return 1;
}

fn void usage(bool help) @noreturn
{
    io::fprintf(io::stderr(), "usage: opng [-hV] command [arg ...]\n")!!;
    if (help) {
        io::fprintf(io::stderr(), "commands:")!!;
        foreach (cmd : cmds) {
            io::fprintf(io::stderr(), " %s", cmd.name)!!;
        }
        
        io::fprintn(io::stderr(), "")!!;
    }
    os::exit(1);
}

/* Utilities */

fn String fault.shortname(self)
{
    String name = self.nameof;
    return name[name.index_of("::") + 2..]!!;
}
