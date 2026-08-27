/* SPDX-License-Identifier: GPL-3.0-or-later */
module cooker::splash;

import std::os::process, std::io, std::compression::qoi;
import patterngen;

/* XXX: when release is being built, open banner file and re-encode as QOI */
fn void? gen() => @pool()
{
    String hash = get_hash();
    
    Generator gen = patterngen::init(hash);
    Canvas canvas = gen.gen(mem, 1024, 640);
    
    qoi::write("splash.qoi", canvas.image,
        &&{ (uint) canvas.width, (uint) canvas.height, RGBA, LINEAR })!;
}

const String GOT_START = "work tree base commit";

fn String get_hash() @local
{
    /* should be plenty for both git and got */
    char[128] out;
    
    if END: (try Process proc = process::spawn({"git", "rev-parse", "HEAD"})) {
        int res = proc.join() ?? -1;
        
        if (res != 0) break END;
        
        usz read = proc.read_stdout(&out, 128) ?? 0;
        String msg = (String) out[:read];
        
        return msg.tcopy();
    }
    
    if END: (try Process proc = process::spawn({"got", "info"})) {
        int res = proc.join() ?? -1;
        
        if (res != 0) break END;
        
        usz read = proc.read_stdout(&out, 128) ?? 0;
        String msg = (String) out[:read];
        
        usz start = msg.index_of(GOT_START)!!;
        start += GOT_START.len + 2; /* color and space */
        msg = msg[start..];
        msg = msg[:msg.index_of_char('\n')!!];
        
        return msg.tcopy();
    }
    
    /* commit hash as of this file getting created */
    return "90c170305ae942ea1a6ab82d3e41319b8651f7be";
}
