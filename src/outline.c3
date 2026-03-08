/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::outline;

import openpngstudio;

import raylib5::rl;

struct Outline {
    Shader shader;
    int color_loc, size_loc;
    bool we_shading;
}

fn void Outline.init(&self, String path)
{
    self.shader = rl::loadShader(null, path.zstr_tcopy());

    self.color_loc = rl::getShaderLocation(self.shader, "outline_color");
    self.size_loc = rl::getShaderLocation(self.shader, "texture_size");
}

fn void Outline.set_color(&self, rl::Color color)
{
    rl::Vector4 n = rl::colorNormalize(color);
    float[4] arr = {n.x, n.y, n.z, n.w};

    rl::setShaderValue(self.shader, self.color_loc, &arr, VEC4);
}

fn void Outline.set_size(&self, rl::Vector2 size)
{
    float[2] arr = {size.x, size.y};

    rl::setShaderValue(self.shader, self.size_loc, &arr, VEC2);
}

fn bool is_selected(Layer layer) => openpngstudio::get_ctx().model.mgr.selected.
    layer == layer;

fn void shading_time()
{
    openpngstudio::get_ctx().outline.we_shading = true;

    // rl::endMode2D();
}

fn void no_shading_time()
{
    Context *ctx = openpngstudio::get_ctx();

    ctx.outline.we_shading = false;

    // rl::beginMode2D(ctx.camera);
}

fn void draw_texture(Texture2D texture, Rectangle source, Rectangle dest, 
    Vector2 origin, float rotation, Color tint)
{
    Context *ctx = openpngstudio::get_ctx();

    if (ctx.outline.we_shading) {
        ctx.outline.set_size({texture.width, texture.height});
        rl::beginShaderMode(ctx.outline.shader);
    }

    rl::drawTexturePro(texture, source, dest, origin, rotation, tint);

    if (ctx.outline.we_shading) {
        rl::endShaderMode();
    }
}
