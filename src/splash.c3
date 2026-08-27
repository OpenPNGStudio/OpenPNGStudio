/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::splash;

import openpngstudio;
import std::os, std::io::path;
import raylib5::rl;
import fons;

const float MARGIN @local = 10.0f;
const int TITLE_SIZE @local = 36;
const int DESC_SIZE @local = 24;
const rl::Color BG @local = { 0x0, 0x0, 0x0, 0xC3 };
const Anchor ANCHOR @local = BOTTOM_RIGHT;

constdef Anchor @local {
    TOP_LEFT,
    TOP_RIGHT,
    BOTTOM_LEFT,
    BOTTOM_RIGHT
}

struct Assets @local {
    rl::Image splash, logo;
}

struct TextBounds @local {
    rl::Vector2 title, desc;
}

fn void run(openpngstudio::Context *self)
{
    self.exe_path = core::whereami()!!;
    Assets assets = load_assets(self);
    
    rl::setConfigFlags(rl::FLAG_WINDOW_TRANSPARENT | rl::FLAG_MSAA_4X_HINT);
    rl::initWindow(1024, 640, "OpenPNGStudio");
    rl::setExitKey(rl::KEY_NULL);
    
    self.fons = fons::init();
    self.font = openpngstudio::load_font(self);
    fons::set_font(self.fons, self.font);
    
    TextBounds bounds = get_bounds(self.fons, self.font);
    rl::Texture2D splash = rl::loadTextureFromImage(assets.splash);
    rl::Texture2D logo = rl::loadTextureFromImage(assets.logo);
    defer rl::unloadTexture(splash);
    defer rl::unloadTexture(splash);
    rl::unloadImage(assets.splash);
    rl::unloadImage(assets.logo);
    
    rl::setTargetFPS(60);
    while (!rl::windowShouldClose()) {
        rl::beginDrawing();
        rl::clearBackground(rl::BLANK);
        rl::drawTexture(splash, 0, 0, rl::WHITE);
        
        draw_logo(self, ANCHOR, logo, bounds);
        rl::endDrawing();
    }
    
    rl::setTargetFPS(0);
    os::exit(1);
}

fn void draw_logo(openpngstudio::Context *self, Anchor anchor,
    rl::Texture2D logo, TextBounds bounds) @local
{
    rl::Vector2 pos = get_pos(anchor, logo.width, logo.height);
    rl::Vector2 size = { 0, 0 };
    rl::drawTextureV(logo, pos, rl::WHITE);
    
    fons::clear_state(self.fons);
    fons::set_font(self.fons, self.font);
    
    switch (anchor) {
    case TOP_LEFT:
    case BOTTOM_LEFT:
        pos.x += logo.width + MARGIN;
        size = { bounds.title.x + MARGIN * 2, logo.height };
        fons::set_align(self.fons, LEFT | TOP);
    case TOP_RIGHT:
    case BOTTOM_RIGHT:
        pos.x -= MARGIN;
        size = { bounds.title.x + MARGIN * 2, logo.height };
        fons::set_align(self.fons, RIGHT | TOP);
    }
    
    switch (anchor) {
    case TOP_LEFT:
    case BOTTOM_LEFT:
        rl::drawRectangleV({ pos.x - MARGIN, pos.y }, size, BG);
    case TOP_RIGHT:
    case BOTTOM_RIGHT:
        rl::drawRectangleV({ pos.x - size.x + MARGIN, pos.y }, size, BG);
    }
    pos.y += MARGIN / 2;
    
    fons::set_size(self.fons, TITLE_SIZE);
    self.fons.draw(pos.x, pos.y, "OpenPNGStudio");
    pos.y += bounds.title.y + MARGIN / 2;
    
    fons::set_size(self.fons, DESC_SIZE);
    self.fons.draw(pos.x, pos.y, "Create & Stream");
    pos.y += bounds.desc.y + MARGIN / 2;
    self.fons.draw(pos.x, pos.y, "PNGTuber models");
}

fn TextBounds get_bounds(fons::Context *ctx, int font) @local
{
    return {
        ctx.measure(font, "OpenPNGStudio", TITLE_SIZE),
        ctx.measure(font, "Create & Stream", DESC_SIZE),
//        ctx.measure(font, "Create & Stream\nPNGTuber models", 18),
    };
}

fn rl::Vector2 get_pos(Anchor anchor, float w, float h) @local @inline
{
    float sw = 1024.0f;
    float sh = 640.0f;
    
    switch (anchor) {
    case TOP_LEFT:
        return { MARGIN, MARGIN, };
    case TOP_RIGHT:
        return { sw - w - MARGIN, MARGIN };
    case BOTTOM_LEFT:
        return { MARGIN, sh - h - MARGIN };
    case BOTTOM_RIGHT:
        return { sw - w - MARGIN, sh - h - MARGIN };
    }
    
    return { -w, -h };
}

fn Assets load_assets(openpngstudio::Context *self) @local => @pool()
{
    Path dir = self.exe_path.parent()!!;
    if (dir.basename() == "build") {
        dir = dir.parent()!!;
        dir = dir.tappend("assets")!!;
    } else {
        dir = dir.parent()!!;
        dir = dir.tappend("share")!!;
        dir = dir.tappend("OpenPNGStudio")!!;
    }
    
    Path splash = dir.tappend("splash.qoi")!!;
    Path logo = dir.tappend("logo.png")!!;
    
    return {
        rl::loadImage(splash.str_view().zstr_tcopy()),
        rl::loadImage(logo.str_view().zstr_tcopy())
    };
}
