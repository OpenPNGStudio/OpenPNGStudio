/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng::dump @if($feature(OPNG_STANDALONE));

import std::io, std::os;
import opng;

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

    argc -= optind;
    argv += optind;

    if (argc < 2) usage();

    Reader? rd = opng::read_file(mem, argv[0].str_view(), { 0x0003 });
    if (catch excuse = rd) {
        io::fprint(io::stderr(), "opng info: ")!!;
        io::fprintn(io::stderr(), excuse.shortname())!!;
        return 1;
    }
    
    defer rd.free();

    Path out = path::new(mem, argv[1].str_view())!!;
    (void) path::rmtree(out);

    (void) path::mkdir(out);

    while (try DirResult res = rd.next_dir()) {
        switch (res.type) {
        case SQLITE:
            @pool() {
                Path db_path = out.tappend("model.db")!!;

                char[] data = mem::temp_array(char, 
                    res.value.sqlite.uncompressed_size);

                rd.read_into(res.value.sqlite.offset, data)!!;
                
                (void) file::save(db_path.str_view(), data);
            };
        case IMAGES:
            foreach (img : res.value.images) {
            @pool() {
                Path file_path = out.tappend(string::tformat("%d.qoi", 
                    img.id))!!;
                    
                char[] data = mem::temp_array(char, img.uncompressed_size);

                rd.read_into(img.offset, data)!!;

                (void) file::save(file_path.str_view(), data);
            };
            }
        default:
        }
    }

    return 0;
}

fn void usage() @local
{
    io::fprintf(io::stderr(), "usage: opng dump [-h] infile dir\n")!!;
    os::exit(1);
}
