

module openpngstudio::layer::group;

import openpngstudio::layer;
import openpngstudio::core::mask;
import openpngstudio::animation;
import std::collections::list, std::io;
import opng;
import nk;

struct LayerGroup (Layer) {
    StaticLayer base;
    List{Layer} layers;
    LayerGroup *parent;

    /* nuklear state */
    CollapseStates tree_state;
}

fn void LayerGroup.init(&self, Allocator alloc, ZString name = null)
{
    self.base.init(alloc, name, null);
    self.layers.init(alloc);
    self.tree_state = nk::MINIMIZED;
}

fn void LayerGroup.free(&self) @dynamic
{
    self.base.free();

    foreach (layer : self.layers) {
        layer.free();
        free(layer.ptr);
    }

    self.layers.free();
}

fn bool LayerGroup.draw(&self, Origin origin) @dynamic
{
    bool mask_test = mask::cmp(mask::get(), self.base.mask);

    if ((self.base.active || self.base.is_toggled) || mask_test) {
        origin.position.x += self.base.position.x;
        origin.position.y += -self.base.position.y;

        origin.scale.x += self.base.scale.x - 1;
        origin.scale.y += self.base.scale.y - 1;

        origin.rotation += self.base.rotation;

        origin.tint = self.base.tint;

        foreach (a : self.base.animations) {
            if (a.a == null) continue;

            BasicAnimation *b = a.a.get_base();
            b.enable(true);
            a.a.animate(&origin);
        }

        foreach (layer : self.layers) {
            layer.draw(origin);
        }

        if (!self.base.toggle) {
            /* spawn live timeout */
            if (!self.base.active && self.base.timeout > 0 && 
                    !self.base.is_timeout_running) {
                if (self.base.mask != mask::DEFAULT) {
                    static_layer::start_timeout(&self.base);
                }
            }
        } else {
            if (!self.base.is_toggle_running && mask_test) {
                if (self.base.mask != mask::DEFAULT) {
                    static_layer::start_toggle(&self.base);
                }
            }
        }

        return true;
    }

    foreach (a : self.base.animations) {
        if (a.a == null) continue;
        BasicAnimation *b = a.a.get_base();
        b.enable(false);
    }

    return false;
}

fn layer::Command LayerGroup.layer_entry(&self, nk::Context *ctx) @dynamic
{
    if (nk::tree_state_push(ctx, nk::TREE_TAB, (CChar*) self.base.name.buffer,
        &self.tree_state)) {
        layer::Command res = static_layer::entry(&self.base, ctx);
        if (res.type != NONE) {
            res.parent = self.parent;
            res.layer = self;
        }

        foreach (layer : self.layers) {
            layer::Command out = layer.layer_entry(ctx);
            if (res.type == NONE && out.type != NONE) {
                if (out.parent == null) out.parent = self;
                res = out;
            }
        }

        nk::tree_state_pop(ctx);
        return res;
    }

    return { NONE, null, null };
}

fn void LayerGroup.config(&self, nk::Context *ctx) @dynamic =>
    static_layer::config(&self.base, ctx);

fn bool LayerGroup.can_cleanup(&self) @dynamic
{
    bool res = self.base.can_cleanup();
    if (!res) return false;

    foreach (layer : self.layers) {
        if (!layer.can_cleanup()) return false;
    }
    
    return true;
}

fn void LayerGroup.add(&self, Layer layer) @inline =>
    self.layers.push(layer);

fn void LayerGroup.del(&self, Layer layer) => self.layers.remove_item(layer);

fn void? LayerGroup.up(&self, layer::Command *sel) @maydiscard
{
    Layer layer = sel.layer;
    usz index = self.layers.index_of(layer)!;

    if (index == 0) {
        if (self.parent == null) return;

        usz parent_index = self.parent.layers.index_of(self)!;
        self.layers.remove_at(0);
        self.parent.layers.insert_at(parent_index, layer);
        sel.parent = self.parent;

        /* if I am group, reparent */
        if (LayerGroup *layer_group = layer.ptr, layer.type == LayerGroup) {
            layer_group.parent = self.parent;
        }
        return;
    }

    Layer prev = self.layers[index - 1];
    if (LayerGroup *group = prev.ptr, prev.type == LayerGroup) {
        if (group.tree_state == nk::MAXIMIZED) {
            self.layers.remove_at(index);
            group.add(layer);
            sel.parent = group;

            /* if I am group, reparent */
            if (LayerGroup *layer_group = layer.ptr, layer.type == LayerGroup) {
                layer_group.parent = group;
            }
            return;
        }
    }

    self.layers.swap(index, index - 1);
}

fn void? LayerGroup.down(&self, layer::Command *sel) @maydiscard
{
    Layer layer = sel.layer;
    usz index = self.layers.index_of(layer)!;

    if (self.layers.len() - 1 == index) {
        if (self.parent == null) return;

        usz parent_index = self.parent.layers.index_of(self)!;
        self.layers.remove_at(index);
        self.parent.layers.insert_at(parent_index + 1, layer);
        sel.parent = self.parent;

        /* if I am group, reparent */
        if (LayerGroup *layer_group = layer.ptr, layer.type == LayerGroup) {
            layer_group.parent = self.parent;
        }
        return;
    }

    Layer next = self.layers[index + 1];
    if (LayerGroup *group = next.ptr, next.type == LayerGroup) {
        if (group.tree_state == nk::MAXIMIZED) {
            self.layers.remove_at(index);
            group.layers.insert_at(0, layer);
            sel.parent = group;

            /* if I am group, reparent */
            if (LayerGroup *layer_group = layer.ptr, layer.type == LayerGroup) {
                layer_group.parent = group;
            }
            return;
        }
    }

    self.layers.swap(index, index + 1);
}

fn void? LayerGroup.pack(&self, Writer *wr) @dynamic
{
    SQLLayerData data = static_layer::prepare_data(&self.base);

    uint layer_id = wr.add_layer_data(data)!;

    foreach (anim : self.base.animations) {
        unreachable("UNIMPLEMENTED");
        /*
        anim.layer_id = layer_id;
        wr.add_animation(anim)!;
        */
    }

    wr.add_layer({self.layers.len(), layer_id})!;

    foreach (layer : self.layers) {
        layer.pack(wr)!;
    }
}
