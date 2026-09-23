/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::animation;

import std::io;
import opng, openpngstudio::util;

const typeid[] TYPES = {Spinner.typeid, Shake.typeid, Fade.typeid, Bounce.typeid, Sine.typeid};
const CChar*[] ANIMATIONS = gen_names();

attrdef @AnimData = @tag("AnimationData", true);

macro gen_names() @local
{
    var $names = {"None"};

    $foreach $type : TYPES:
        var $Type = $typefrom($type);

        $names = $names +++ $Type.nameof;
    $endforeach

    return $names;
}

fn Animation populate_animation(int idx)
{
    if (idx >= TYPES.len || idx < 0) return null;

    $foreach $i, $type : TYPES:
        if ($i == idx) {
            var $Type = $typefrom($type);

            $Type *anim = mem::new($Type);
            anim.init();
            return anim;
        }
    $endforeach

    return null;
}

macro usz data_size($Type) @local
{
    usz $size = 0;

    $foreach $m : $Type.membersof:
        $if $m.has_tagof("AnimationData"):
            $size += $m.sizeof;
        $endif
    $endforeach

    return $size;
}

fn void unpack_animation(Animation anim, char[] data)
{
    $foreach $i, $type : TYPES:
        if (anim.type == $type) {
            var $Type = $typefrom($type);
            $Type *self = anim.ptr;

            usz $progress = 0;

            $foreach $m : $Type.membersof:
                $if $m.has_tagof("AnimationData"):
                    mem::copy(&$m.get(*self), data[$progress..], $m.sizeof);
                    $progress += $m.sizeof;
                $endif
            $endforeach

            self.reset();
        }
    $endforeach
}

fn void? pack_animation(Animation anim, Writer *wr, uint layer_id)
{
    $foreach $i, $type : TYPES:
        if (anim.type == $type) {
            var $Type = $typefrom($type);
            $Type *self = anim.ptr;

            usz $data_size = data_size($Type);
            SQLAnimation base = prepare_data(self);

            base.type = $i + 1;
            base.layer_id = layer_id;
            base.data = malloc($data_size);
            base.data_size = $data_size;

            char[] buf = base.data[:$data_size];

            usz $progress = 0;

            $foreach $m : $Type.membersof:
                $if $m.has_tagof("AnimationData"):
                    util::@copy_into(buf[$progress..], $m.get(*self));
                    $progress += $m.sizeof;
                $endif
            $endforeach

            wr.add_animation(base)!;
        }
    $endforeach
}