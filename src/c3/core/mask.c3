/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::core::mask;

import raylib5::rl;
import std::io, std::ascii, std::math;
import nk;

alias Mask = ulong;

/*
 * Mask structure
 * 0-2 bits - state
 * 3-6 bits - mod keys
 * 7-33 bits - ASCII key
 */

/* true when one matches */
const Mask QUIET = 1; /* << 0 */
const Mask TALK = 1 << 1;
const Mask PAUSE = 1 << 2;

/* true when all selected match */
const Mask SHIFT = 1 << 3;
const Mask CTRL = 1 << 4;
const Mask SUPER = 1 << 5;
const Mask META = 1 << 6;

/*
 * 1ULL << (toupper(key) - 'A' + KEY_START)
 * true when one matches, layer can be active with only one keybinding
 */
const Mask KEY_START = 7;

const Mask DEFAULT_LAYER_MASK = QUIET | TALK | PAUSE;

Mask current @local = QUIET;

fn void set(Mask mask) @export("set_current_mask")
{
    current = mask;
}

fn Mask get() @export("get_current_mask")
{
    return current;
}

fn void update(Mask *mask) @export("set_key_mask")
{
    int key = rl::getKeyPressed();
    if (key >= 'A' && key <= 'Z') {
        *mask |= 1UL << ((Mask) key - 'A' + KEY_START);
    }

    if (rl::isKeyPressed(rl::KEY_LEFT_SHIFT) ||
        rl::isKeyPressed(rl::KEY_RIGHT_SHIFT)) *mask |= SHIFT;

    if (rl::isKeyPressed(rl::KEY_LEFT_CONTROL) ||
        rl::isKeyPressed(rl::KEY_RIGHT_CONTROL)) *mask |= CTRL;

    if (rl::isKeyPressed(rl::KEY_LEFT_SUPER) ||
        rl::isKeyPressed(rl::KEY_RIGHT_SUPER)) *mask |= SUPER;

    if (rl::isKeyPressed(rl::KEY_LEFT_ALT) ||
        rl::isKeyPressed(rl::KEY_RIGHT_ALT)) *mask |= META;
}

fn void handle(Mask *mask) @export("handle_key_mask")
{
    Mask m = *mask;
    Mask new_mask = 0;

    for (int i = 0; i <= 26; i++) {
        Mask bit = 1UL << ((Mask) i + KEY_START);
        if (m & bit) {
            if (rl::isKeyDown((KeyboardKey) i + 'A')) new_mask |= bit;
        }
    }

    if (rl::isKeyDown(rl::KEY_LEFT_SHIFT) ||
        rl::isKeyDown(rl::KEY_RIGHT_SHIFT)) new_mask |= SHIFT;

    if (rl::isKeyDown(rl::KEY_LEFT_CONTROL) ||
        rl::isKeyDown(rl::KEY_RIGHT_CONTROL)) new_mask |= CTRL;

    if (rl::isKeyDown(rl::KEY_LEFT_SUPER) ||
        rl::isKeyDown(rl::KEY_RIGHT_SUPER)) new_mask |= SUPER;

    if (rl::isKeyDown(rl::KEY_LEFT_ALT) ||
        rl::isKeyDown(rl::KEY_RIGHT_ALT)) new_mask |= META;

    for (int i = 0; i < 3; i++) new_mask |= 1UL << i;

    *mask &= new_mask;
}

fn bool cmp(Mask mask, Mask target) @export("test_masks")
{
    Mask[3] states = {QUIET, TALK, PAUSE};
    bool res = false;
    bool has_mask = false;

    /* check state */
    for (int i = 0; i < 3; i++) {
        Mask extract_mask = mask & states[i];
        Mask extract_layer = target & states[i];

        if (extract_layer == 0) continue;

        if (extract_mask == extract_layer) {
            res = true;
            break;
        }

        has_mask = true;
    }

    Mask[4] mods = {SHIFT, CTRL, SUPER, META};

    bool is_mod_set = false;
    for (int i = 0; i < 4; i++) {
        if (target & mods[i]) {
            is_mod_set = true;
            break;
        }
    }

    if (is_mod_set) {
        for (int i = 0; i < 4; i++) {
            Mask extract_mask = mask & mods[i];
            Mask extract_layer = target & mods[i];
            if (extract_mask != extract_layer) return false;
        }

        if (has_mask && res == true) { res = true;}
        else if (!has_mask && res == false) { res = true; }
    }

    int has_key = -1;
    for (int i = 0; i <= 26; i++) {
        if (target & ((Mask) 1UL << ((Mask) i + KEY_START))) {
            has_key = i;
            break;
        }
    }

    if (has_key != -1) {
        if (!(mask & ((Mask) 1UL << ((Mask) has_key + KEY_START)))) return false;

        if (has_mask && res == true) { res = true; }
        else if (!has_mask && res == false) { res = true; }
    }

    return res;
}

fn void reset(Mask *mask)
{
    Mask new_mask = 0;
    for (int i = 0; i < 7; i++) new_mask |= 1UL << i;

    *mask &= new_mask;
}

fn nk::Bool filter(nk::TextEdit *box, nk::Rune unicode) @local
{
    if ((unicode >= 'a' && unicode <= 'z') || (unicode >= 'A' && unicode <= 'Z')) {
        return true;
    }

    return false;
}

fn void configure(Mask *mask, char *input_buffer, int *input_size,
    nk::Context *ctx, ZString activation) @export("configure_mask")
{
    float win_width = nk::window_get_width(ctx);
    float min_width = math::max(win_width * 0.49f, 250.0f);
    nk::Rect bounds;

    nk::layout_row_template_begin(ctx, 35);
    nk::layout_row_template_push_dynamic(ctx);
    nk::layout_row_template_push_variable(ctx, min_width);
    nk::layout_row_template_end(ctx);

    nk::label(ctx, (CChar*) activation, nk::TEXT_LEFT);
    if (nk::group_begin(ctx, (CChar*) activation, nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);
        nk::Rect b = nk::widget_bounds(ctx);
        if (nk::combo_begin_label(ctx, "When", nk::vec2(min_width, 128))) {
            nk::layout_row_dynamic(ctx, 32, 1);
            nk::checkbox_flags_label(ctx, "Quiet", (CUInt*) mask, QUIET);
            nk::checkbox_flags_label(ctx, "Talking", (CUInt*) mask, TALK);
            nk::checkbox_flags_label(ctx, "Pause", (CUInt*) mask, PAUSE);
            nk::layout_row_dynamic(ctx, 4, 1);
            nk::spacer(ctx);
            nk::combo_end(ctx);
        }
        nk::group_end(ctx);
    }

    nk::label(ctx, "Modifier keys", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Modifier Keys", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);
        nk::Rect b = nk::widget_bounds(ctx);
        if (nk::combo_begin_label(ctx, "Keys", nk::vec2(b.w, 144))) {
            nk::layout_row_dynamic(ctx, 32, 1);
            nk::checkbox_flags_label(ctx, "Shift", (CUInt*) mask, SHIFT);
            nk::checkbox_flags_label(ctx, "Control", (CUInt*) mask, CTRL);
            nk::checkbox_flags_label(ctx, "Super (Windows Key)", (CUInt*) mask,
                SUPER);
            nk::checkbox_flags_label(ctx, "Alt", (CUInt*) mask, META);
            nk::layout_row_dynamic(ctx, 4, 1);
            nk::spacer(ctx);
            nk::combo_end(ctx);
        }
        nk::group_end(ctx);
    }

    nk::label(ctx, "Key Shortcut", nk::TEXT_LEFT);
    if (nk::group_begin(ctx, "Key Shortcut", nk::WINDOW_NO_SCROLLBAR)) {
        nk::layout_row_dynamic(ctx, 30, 1);
        nk::edit_string(ctx, nk::EDIT_SIMPLE, (CChar*) input_buffer, input_size, 2,
            &filter);
        if (*input_size > 0) {
            input_buffer[0] = ascii::to_upper(input_buffer[0]);
            *mask |= 1ULL << ((Mask) input_buffer[0] - 'A' + KEY_START);
        } else {
            reset(mask);
        }
        nk::group_end(ctx);
    }
}
