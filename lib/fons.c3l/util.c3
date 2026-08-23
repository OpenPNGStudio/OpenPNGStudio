/* SPDX-License-Identifier: BSD-3-Clause */
module fons;

import raylib5::rl;
import std::io, std::math;

faultdef FAILED_ADDING_FONT;

const ATLAS_GEOMETRY = 512;
const MAX_ATLAS_SIZE = 2048;

fn Context *init()
{
    Context *fs = initialize_raylib(ATLAS_GEOMETRY, ATLAS_GEOMETRY,
        ZERO_TOPLEFT);
    
    set_error_callback(fs, fn (userdata, error, val) {
        Context *self = userdata;
        
        if (error == ATLAS_FULL) {
            CInt width, height;
            get_atlas_size(self, &width, &height);
            CInt old_w, old_h;
            old_w = width;
            old_h = height;
            
            if (width == height) {
                width = math::min(width * 2, MAX_ATLAS_SIZE);
            } else {
                height = math::min(height * 2, MAX_ATLAS_SIZE);
            }
            
            if (old_w == width && old_h == height) {
                reset_atlas(self, width, height);
            } else {
                expand_atlas(self, width, height);
            }
        }
    }, fs);
    return fs;
}

fn int? Context*.add(self, ZString name, ZString path)
{
    int idx = add_font(self, name, path);
    
    return idx != INVALID ? idx : FAILED_ADDING_FONT~;
}

fn Vector2 Context*.measure(self, int font, ZString text, float size)
{
    clear_state(self);
    set_font(self, font);
    set_spacing(self, 0);
    set_align(self, LEFT | TOP);
    set_size(self, size);
    
    float[4] bounds;
    text_bounds(self, 0, 0, text, null, &bounds);

    return {
        (bounds[2] - bounds[0]),
        (bounds[3] - bounds[1])
    };
}

extern fn void custom_blend();

fn void Context*.draw(self, float x, float y, ZString text)
{
    rl::beginBlendMode(5);
    fons::draw_text(self, x, y, text, null);
    custom_blend();
}

fn float measure_text(Context *ctx, int font, ZString txt, float height)
    @export("measure_text") => ctx.measure(font, txt, height).x;

fn void cdraw_text(Context *ctx, int font, float x, float y, ZString txt,
    float height, rl::Color color) @export("draw_text")
{
    fons::set_size(ctx, height);
    fons::set_color(ctx, convert_color(color));
    ctx.draw(x, y, txt);
}
