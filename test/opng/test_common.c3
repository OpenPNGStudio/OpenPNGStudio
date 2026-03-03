/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng_test_common;

import opng;

const WriterConfig CFG = {
    0x0003, NONE, NONE, NONE,
};

const ReaderConfig RCFG = {
    0x0003,
};

const SQLLayerData DATA = {
    "foo",
    {-5, 5},
    {1, 1},
    0,
    0xFF333333,
    0,
    0,
    77,
    false
};

const char[] IMG = "Hello, World";
