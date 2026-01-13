#!/bin/sh

PREFIX="${1:-/usr/local}"
BIN="$PREFIX/bin"
SHARE="$PREFIX/share/OpenPNGStudio"
APPS="$PREFIX/share/applications"
ICONS="$PREFIX/share/icons/hicolor/512x512/apps"

set -e

mkdir -p $BIN
mkdir -p $SHARE
mkdir -p $APPS
mkdir -p $ICONS

cp build/OpenPNGStudio $BIN/
cd assets
cp -r . $SHARE/
cd ..
cp -r licenses/ $SHARE/
cp assets/logo.png $ICONS/dev.lowbytefox.OpenPNGStudio.png
cp dev.lowbytefox.OpenPNGStudio.desktop $APPS/
