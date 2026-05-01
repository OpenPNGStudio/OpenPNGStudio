/* SPDX-License-Identifier: GPL-3.0-or-later */
module openpngstudio::util;

<*
 @require buf.len >= data.len
*>
fn void copy_into(char[] buf, char[] data)
{
    foreach (i, c : data) {
        buf[i] = c;
    }
}

macro @copy_into(#buf, #val) => copy_into(#buf, @as_char_view(#val));
