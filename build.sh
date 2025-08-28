#!/bin/sh
if [ "$(basename $(pwd))" = "build" ]; then
    cd ..
fi

RELEASE_BUILD="${RELEASE_BUILD:-false}"

set -e

c3c compile-run -o $(mktemp /tmp/XXXXXXX) build.c3 ./build-files/* -- $RELEASE_BUILD
