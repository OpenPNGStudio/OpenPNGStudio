#include <raylib.h>
#include <core/mask.h>

static mask_t current_mask = 0;

void set_current_mask(mask_t mask)
{
    current_mask = mask;
}

mask_t get_current_mask()
{
    return current_mask;
}

void set_key_mask(mask_t *mask)
{
    int key = GetKeyPressed();
    if (key >= 'A' && key <= 'Z')
        *mask |= 1ULL << (key - 'A' + KEY_START);

    if (IsKeyPressed(KEY_LEFT_SHIFT) || IsKeyPressed(KEY_RIGHT_SHIFT))
        *mask |= SHIFT;

    if (IsKeyPressed(KEY_LEFT_CONTROL) || IsKeyPressed(KEY_RIGHT_CONTROL))
        *mask |= CTRL;

    if (IsKeyPressed(KEY_LEFT_SUPER) || IsKeyPressed(KEY_RIGHT_SUPER))
        *mask |= SUPER;

    if (IsKeyPressed(KEY_LEFT_ALT) || IsKeyPressed(KEY_RIGHT_ALT))
        *mask |= META;
}

void handle_key_mask(mask_t *mask)
{
    mask_t m = *mask;
    mask_t new_mask = 0;

    for (int i = 0; i <= 26; i++) {
        mask_t bit = (1ULL << (i + KEY_START));
        if (m & bit) {
            if (IsKeyDown(i + 'A'))
                new_mask |= bit;
        }
    }

    if (IsKeyDown(KEY_LEFT_SHIFT) || IsKeyDown(KEY_RIGHT_SHIFT))
        new_mask |= SHIFT;

    if (IsKeyDown(KEY_LEFT_CONTROL) || IsKeyDown(KEY_RIGHT_CONTROL))
        new_mask |= CTRL;

    if (IsKeyDown(KEY_LEFT_SUPER) || IsKeyDown(KEY_RIGHT_SUPER))
        new_mask |= SUPER;

    if (IsKeyDown(KEY_LEFT_ALT) || IsKeyDown(KEY_RIGHT_ALT))
        new_mask |= META;

    for (int i = 0; i < 3; i++)
        new_mask |= 1ULL << i;

    *mask &= new_mask;
}

bool test_masks(mask_t mask, mask_t target)
{
    int states[] = {QUIET, TALK, PAUSE};

    bool res = false;
    bool has_mask = false;

    /* check state */
    for (int i = 0; i < 3; i++) {
        uint64_t extract_mask = mask & states[i];
        uint64_t extract_layer = target & states[i];

        if (extract_layer == 0)
            continue;

        if (extract_mask == extract_layer) {
            res = true;
            break;
        }

        has_mask = true;
    }

    int mods[] = {SHIFT, CTRL, SUPER, META};

    bool is_mod_set = false;
    for (int i = 0; i < 4; i++) {
        if (target & mods[i]) {
            is_mod_set = true;
            break;
        }
    }

    if (is_mod_set) {
        for (int i = 0; i < 4; i++) {
            uint64_t extract_mask = mask & mods[i];
            uint64_t extract_layer = target & mods[i];
            if (extract_mask != extract_layer)
                return false;
        }

        if (has_mask && res == true)
            res = true;
        else if (!has_mask && res == false)
            res = true;
    }

    int has_key = -1;
    for (int i = 0; i <= 26; i++) {
        if (target & (1ULL << (i + KEY_START))) {
            has_key = i;
            break;
        }
    }

    if (has_key != -1) {
        if (!(mask & (1ULL << (has_key + KEY_START))))
            return false;

        if (has_mask && res == true)
            res = true;
        else if (!has_mask && res == false)
            res = true;
    }

    return res;
}
