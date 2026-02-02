/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::layer::group;

import openpngstudio::layer;
import openpngstudio::core::mask;
import openpngstudio::animation;
import std::collections::list;
import nk;

struct LayerGroup (Layer) {
    StaticLayer base;
    List{Layer} layers;
    LayerGroup *parent;

    /* nuklear state */

    CollapseStates tree_state;
}

fn void LayerGroup.init(&self, Allocator alloc)
{
    self.base.init(alloc, null);
    self.layers.init(alloc);
    self.tree_state = nk::MAXIMIZED;
}

fn void LayerGroup.free(&self) @dynamic
{
    defer self.layers.free();

    foreach (layer : self.layers) {
        layer.free();        
    }
}

fn bool LayerGroup.draw(&self, Origin origin) @dynamic
{
    bool mask_test = mask::cmp(mask::get(), self.base.mask);

    if ((self.base.active || self.base.is_toggled) || mask_test) {
        origin.position.x += self.base.position.x;
        origin.position.y += -self.base.position.y;

        origin.scale.x += self.base.scale.x;
        origin.scale.y += self.base.scale.y;

        origin.rotation += self.base.rotation;

        origin.tint = self.base.tint;

        foreach (a : self.base.animations) {
            BasicAnimation *b = a.a.get_base();
            b.enable(true);
            a.a.animate(&origin);
        }

        foreach (layer : self.layers) {
            layer.draw(origin);
        }

        if (!self.base.toggle) {
            /* spawn live timeout */
            if (!self.base.active && self.base.timeout > 0) {
                // TODO: start timeout 
            }
        } else {
            if (!self.base.is_toggle_running && mask_test) {
                // TODO: start toggle
            }
        }

        return true;
    }

    foreach (a : self.base.animations) {
        BasicAnimation *b = a.a.get_base();
        b.enable(false);
    }

    return false;
}

/* TODO: make functional! */
fn layer::Command LayerGroup.layer_entry(&self, nk::Context *ctx) @dynamic
{
    if (nk::tree_state_push(ctx, nk::TREE_TAB, (CChar*) self.base.name.buffer,
        &self.tree_state)) {
        layer::Command res = static_layer::entry(&self.base, ctx);

        foreach (layer : self.layers) {
            layer.layer_entry(ctx);
        }

        nk::tree_state_pop(ctx);
        return res;
    }

    return { NONE, null, null };
}

fn void LayerGroup.config(&self, nk::Context *ctx) @dynamic =>
    static_layer::config(&self.base, ctx);

fn void LayerGroup.add(&self, Layer layer) @dynamic @inline =>
    self.layers.push(layer);
