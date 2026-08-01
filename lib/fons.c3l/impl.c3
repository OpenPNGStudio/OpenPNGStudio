/* SPDX-License-Identifier: BSD-3-Clause */
module fons @local;

import raylib5::rl;
import std::io, std::math;

struct ImplContext {
    Texture2D texture;
    Image cached;
    int width, height;
}

fn CInt create(void *userdata, CInt width, CInt height)
{
    ImplContext* ctx = userdata;
    
    ctx.cached = {
        .data = calloc((usz) (width * height * 2)), 
        .width = width,
        .height = height,
        .mipmaps = 1,
        .format = PixelFormat.UNCOMPRESSED_GRAY_ALPHA
    };

    ctx.texture = rl::loadTextureFromImage(ctx.cached);
    
    ctx.width = width;
    ctx.height = height;

    return 1;
}

fn CInt resize(void *userdata, CInt width, CInt height)
{
    ImplContext* ctx = userdata;
    
    if (ctx.width == width && ctx.height == height) {
        rl::updateTexture(ctx.texture, ctx.cached.data);
        return 1;
    } else {
        free(ctx.cached.data);
        rl::unloadTexture(ctx.texture);
        return create(userdata, width, height);
    }
}

fn void update(void *userdata, CInt *rect, CUChar *data)
{
    ImplContext* ctx = userdata;
    
    int x = rect[0];
    int y = rect[1];
    int w = rect[2] - rect[0];
    int h = rect[3] - rect[1];
    
    @pool() {
        CUChar *tight_buffer = tmalloc((isz) (w * h * 2));
        
        for (int row = 0; row < h; row++) {
            for (int col = 0; col < w; col++) {
                int src_x = x + col;
                int src_y = y + row;
                int src_idx = (src_y * ctx.width) + src_x;
                
                int dst_idx = ((row * w) + col) * 2;
                
                CUChar pixel = data[src_idx];
                
                tight_buffer[dst_idx]     = pixel;
                tight_buffer[dst_idx + 1] = pixel;
            }
        }
        
        rlUpdateTexture(ctx.texture.id, x, y, w, h, 2, tight_buffer);
    };
}

extern fn bool rlCheckRenderBatchLimit(CInt vcount);
extern fn void rlUpdateTexture(CUInt id, CInt offsetX, CInt offsetY, CInt width,
    CInt height, CInt format, void *data);
extern fn void rlSetTexture(CUInt id);
extern fn void rlBegin(CInt mode);
extern fn void rlColor4ub(char r, char g, char b, char a);
extern fn void rlTexCoord2f(float x, float y);
extern fn void rlVertex2f(float x, float y);
extern fn void rlEnd();
extern fn void rlUnloadTexture(CUInt id);

fn void draw(void *userdata, float *verts, float *tcoords, CUInt *colors,
    CInt nverts)
{
    ImplContext* ctx = userdata;
    
    rlCheckRenderBatchLimit(nverts);
    rlSetTexture(ctx.texture.id);
    
    rlBegin(0x0004);
    
    for (int i = 0; i < nverts; i++) {
        CUInt c = colors[i];
        CUChar r = (CUChar) c & 0xff;
        CUChar g = (CUChar) (c >> 8) & 0xff;
        CUChar b = (CUChar) (c >> 16) & 0xff;
        CUChar a = (CUChar) (c >> 24) & 0xff;
        
        rlColor4ub(r, g, b, a);
        rlTexCoord2f(tcoords[i * 2], tcoords[i * 2 + 1]);
        rlVertex2f(verts[i * 2], verts[i * 2 + 1]);
    }
    
    rlEnd();
    rlSetTexture(0);
}

fn void delete(void *userdata)
{
    ImplContext* ctx = userdata;
    rlUnloadTexture(ctx.texture.id);
    free(ctx);
}

fn Context *initialize_raylib(int width, int height, Flags flags) @public
{
    Params params;
    ImplContext* ctx = malloc(ImplContext.sizeof);
    
    params.width = width;
    params.height = height;
    params.flags = flags;
    params.create = &create;
    params.resize = &resize;
    params.update = &update;
    params.draw = &draw;
    params.delete = &delete;
    params.userdata = ctx;

    return create_internal(&params);
}

fn CUInt convert_color(Color color) @public
{
    return ((CUInt) color.a << 24) | 
           ((CUInt) color.b << 16) | 
           ((CUInt) color.g << 8)  | 
           (CUInt) color.r;
}
