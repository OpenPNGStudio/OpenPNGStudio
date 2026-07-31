/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::ui;

import openpngstudio;
import std::io, std::collections::list;
import raylib5::rl;

const HEIGHT = 34;
const SPACING = 7.5;
const DEADLINE = 5; /* 5s */

struct Toast {
    ZString message;
    float width, height;
    char stl; /* seconds to live */
    short opacity;
}

alias Toaster = List{Toast};

fn void Toaster.draw(&self, Context *ctx)
{
    float y = ctx.height - (float) (self.len() * HEIGHT);
    y -= (float) (self.len() - 1) * SPACING + (SPACING * 2);
    
    foreach (i, &current : self) {
        float dy = y + (float) (i * HEIGHT);
        
        Rectangle dest = {
            ctx.width / 2.0 - current.width / 2.0, dy, current.width, HEIGHT
        };
        
        if (!current.stl) {
            char to_sub = (char) (rl::getFrameTime() * 1000);
            
            current.opacity -= to_sub > current.opacity ? current.opacity : to_sub;
        }
        
        rl::drawRectangleRounded(dest, 1.0f, 16, { 0x20, 0x20, 0x20,
            (char) current.opacity });
        
        rl::drawTextEx(ctx.font, current.message, {
            dest.x + HEIGHT / 2.0,
            dest.y + HEIGHT / 2.0 - current.height / 2.0
        }, 20, 2.0, { 0xFF, 0xFF, 0xFF, (char) current.opacity });
        
        y += SPACING;
    }
}

fn void Toaster.add(&self, Context *ctx, ZString msg, char timeout = DEADLINE)
{
    float width = ctx.width;
    Vector2 size = rl::measureTextEx(ctx.font, msg, 20, 2.0);
    
    self.push({
        msg,
        size.x + HEIGHT,
        size.y,
        timeout,
        255
    });
}
