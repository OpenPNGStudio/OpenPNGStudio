/* SPDX-License-Identifier: GPL-3.0-or-later */
module opng_test_common;

import opng;

const WriterConfig CFG = {
    0x0003, NONE, NONE, NONE,
};

const ReaderConfig RCFG = {
    0x0003,
};

const LayerInfo INFO = {
    6, 7, 180, 1000, false, 0xFF, 0, 0
};
