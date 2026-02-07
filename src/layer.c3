/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::layer;

import raylib5::rl;
import nk;

struct Origin {
    rl::Vector2 position, scale;
    float rotation;
    rl::Color tint;
}

enum CommandType : char {
    NONE,
    SELECT,
    CONFIG,
    DELETE
}

struct Command {
    CommandType type;
    Layer layer;
    LayerGroup *parent;
}

interface Layer {
    fn bool draw(Origin origin);
    fn Command layer_entry(nk::Context *ctx);
    fn void config(nk::Context *ctx);
    fn void free();
    fn bool can_cleanup();
}
