#!/bin/sh
if [ "$(basename $(pwd))" = "build" ]; then
    cd ..
fi

if [ "$RELEASE_BUILD" = "true" ]; then
    RELEASE_BUILD="RelWithDebInfo"
else
    RELEASE_BUILD="Debug"
fi

set -e

cmake -B build -G Ninja -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE="$RELEASE_BUILD"
cd build
ninja
mkdir -p miniroot
DESTDIR=./miniroot/ ninja install
c3c build
