#!/bin/sh

PREFIX="$1"

if [ -z "$PREFIX" ]; then
    echo "Please run the script with prefix dir!"
    exit 1
fi

BIN="$PREFIX/bin"
SHARE="$PREFIX/share/OpenPNGStudio"

mkdir -p $BIN
mkdir -p $SHARE

cp build/OpenPNGStudio $BIN/
cd assets
cp -r . $SHARE/
cd ..
cp -r licenses/ $SHARE/
