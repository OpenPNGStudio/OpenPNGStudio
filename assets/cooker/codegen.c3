/* SPDX-License-Identifier: GPL-3.0-or-later */
module cooker::code;

import std::io, std::collections::map;
import cooker;

String header @local = `/* GENERATED ASSET BY COOKER, DO NOT EDIT */
/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui::icons;

import nk;
import raylib5::rl;

alias IconLoc @local = usz[4];

enum Type : (usz x, usz y, usz w, usz h) {
`;

String footer @local = `            DB_SIZE {0, 0, 0, 0},
}

nk::Image atlas @local;
nk::Image[Type.DB_SIZE.ordinal] db @local;

extern fn nk::Image load_nk_image(ZString path) @extern("LoadNuklearImage");
extern fn void unload_nk_image(nk::Image) @cname("UnloadNuklearImage");

fn void init(ZString path)
{
    atlas = load_nk_image(path);
    
    $foreach $m : Type.values:
    {
        Type $val = $m;
        
        $if $val.ordinal < Type.DB_SIZE.ordinal:
            db[$val.ordinal] = nk::subimage_ptr(atlas.handle.ptr, atlas.w,
                atlas.h, nk::rect($val.x, $val.y, $val.w, $val.h));
        $endif
    }
    $endforeach
}

fn nk::Image get(Type t) @inline => db[t.ordinal];
fn rl::Rectangle get_size(Type t) @inline => { 0, 0, t.w, t.h };

fn void draw(Type t, rl::Vector2 pos, float rotation, float scale, rl::Color
    tint) @inline
{
    rl::drawTexturePro(*(Texture2D*) atlas.handle.ptr, { t.x, t.y, t.w, t.h }, {
        pos.x, pos.y, t.w * scale, t.h * scale
    }, { 0, 0 }, rotation, tint);
}

fn void cleanup()
{
    unload_nk_image(atlas);
}
`;

fn void? gen(HashMap{String, Icon} map)
{
    log(PREPARE, "Preparing codegen");
    File dst = file::open("cooked_assets.c3", "w")!;
    defer (void) dst.close();
    dst.write(header)!;
    
    map.@each(; String name, Icon icon) {
        name.convert_to_upper();
        foreach (&c : name) { if (*c == '-') *c = '_'; }
        
        cooker::Rect *rect = icon.ref;
        (void) io::fprintfn(&dst, "    %15s { %d, %d, %d, %d },", name, rect.x,
            rect.y, rect.w, rect.h);
    };
    
    dst.write(footer)!;
}
