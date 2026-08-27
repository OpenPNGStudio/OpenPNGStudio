/* SPDX-License-Identifier: GPL-3.0-or-later */
module cooker;

import std::io, std::collections::map;

const PADDING @builtin = 2;

enum Progress : (String label) {
    COLLECT { "collect" },
    LOAD    { "load   " },
    SIZE    { "size   " },
    PREPARE { "prepare" },
    SPLIT   { "?      " },
    LOADED  { "loaded " },
    PACK    { "pack   " },
    PACKED  { "packed " },
    SAVED   { "saved  " },
}

struct Rect {
    CInt id;
    CInt w, h;
    /* out */
    CInt x, y;
    CInt was_packed;
}

struct Icon {
    Rect *ref;
    char *data;
}

extern fn char *load_img(ZString path, Rect *ref);

fn int main(String[] args)
{
    banner();
    
    if (args.len != 2) {
        (void) io::eprintfn("usage: cooker asset_dir copy_dst");
        return 1;
    }
    
    Path cwd = path::cwd(tmem)!!;
    
    (void) path::chdir(args[1]);
    
    PathList icons = path::ls(tmem, path::new(tmem, "icons"), no_dirs: true,
        no_symlinks: true)!!;
    
    usz len = icons.len();
    usz capacity = next_po2(len);
    
    Rect[] storage = mem::temp_array(Rect, capacity);
    Rect[] arr = storage[:len];
    
    HashMap{String, Icon} map;
    map.tinit((uint) capacity);
    
    log(COLLECT, "Collected %d icons", len);
    log(LOAD, "Loading %d icons", len);
    for (int i = 0; i < len; i++) {
        @pool() {
            Path icon = icons[i];
            String name = icon.str_view();
            usz last = name.rindex_of_char('.')!!;
            name = name[:last];
            
            ZString dst = string::tformat_zstr("icons/%s", icon.str_view());
            Rect *ref = &arr[i];
            ref.id = i;
            
            char *data = load_img(dst, ref);
            
            ref.w += PADDING;
            ref.h += PADDING;
            
            map.set(name, { ref, data });
            log(LOADED, "Loaded icon %s", name);
        };
    }
    
    atlas::gen(map, arr)!!;
    code::gen(map)!!;
    
    /* because meson is stupid */
    (void) path::chdir(cwd);
    
    Path orig = path::new(tmem, args[1])!!;
    orig = orig.tappend("icon_atlas.qoi")!!;
    
    {
        File in = file::open(orig.str_view(), "rb")!!;
        File out = file::open("assets/icon_atlas.qoi", "wb")!!;
        defer (void) in.close();
        defer (void) out.close();
        
        io::copy_to(&in, &out)!!;
    }
    return 0;
}

fn usz next_po2(usz cap)
{
    usz v = cap;
    v--;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;
    v++;
    
    return v;
}

fn void log(Progress progress, String fmt, args...) @builtin
{
    String prefix = "As";
    
    if (progress > SPLIT) prefix = "Co";
    
    io::printf("  [%s/%s] ", prefix, progress.label);
    io::printfn(fmt, ...args);
}

fn void banner() @local
{
    io::print(`  [As]set  [Co]oker
  =================
`);
}
