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
LIBUV_PATH=$(find miniroot -name "libuv.a")
LIBUV_FIXED=$(echo "$LIBUV_PATH" | sed "s/libuv.a/libuvstatic.a/") 

# force linker to link with static libuv
cp "$LIBUV_PATH" "$LIBUV_FIXED"
c3c build OpenPNGStudio-linux-x64
c3c build opng
