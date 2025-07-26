#!/bin/sh
set -e
c3c compile-run -o $(mktemp /tmp/XXXXXXX) build.c3 ./build-files/*
cd build
./OpenPNGStudio
