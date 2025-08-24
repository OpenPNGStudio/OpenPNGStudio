#!/bin/sh
if [ "$(basename $(pwd))" = "build" ]; then
    cd ..
fi

set -e
c3c compile-run -o $(mktemp /tmp/XXXXXXX) build.c3 ./build-files/*
