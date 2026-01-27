/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::image;

import raylib5::rl;

struct Image {
    rl::Image image;
    rl::Texture2D texture;
    char[] file_content; /* only for GIFs */
}
