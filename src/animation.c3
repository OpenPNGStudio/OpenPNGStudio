/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::animation;

import openpngstudio::layer;
import nk;

interface Animation {
    fn void update(ulong now);
    fn void animate(Origin *origin);
    fn void start();
    fn void stop();
}

struct AnimationEntry {
    Animation a;
    char[2] input_buffer;
    int input_length;
}

fn void AnimationEntry.config(&self, nk::Context *ctx)
{
    
}
