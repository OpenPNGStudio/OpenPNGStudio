#!/bin/sh

rm -rf build-mingw
CC='x86_64-w64-mingw32-gcc' CXX='x86_64-w64-mingw32-g++' LD='x86_64-w64-mingw32-ld' meson setup --cross-file x86_64-w64-mingw32.txt build-mingw