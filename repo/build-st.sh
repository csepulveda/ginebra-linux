#!/bin/bash
# build-st.sh - Generates st.pkg.tar.gz

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
BUILD_DIR="$REPO_DIR/build"
TOOLCHAIN="/home/cesar/floppinux/i486-linux-musl-cross"
XORG_DEPS="$BUILD_DIR/xorg-deps"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

if [ ! -d "$XORG_DEPS" ]; then
    echo "ERROR: xorg-deps not found. Run build-xfbdev.sh first."
    exit 1
fi

export PATH="$TOOLCHAIN/bin:$PATH"
export CC=i486-linux-musl-gcc

ST_VER="0.9.2"
[ -f "st-${ST_VER}.tar.gz" ] || curl -LO "https://dl.suckless.org/st/st-${ST_VER}.tar.gz"
rm -rf "st-${ST_VER}"
tar -xzf "st-${ST_VER}.tar.gz"
cd "st-${ST_VER}"

cat > config.mk << CONFIGMK
VERSION = $ST_VER
PREFIX = /usr
X11INC = $XORG_DEPS/include
X11LIB = $XORG_DEPS/lib
PKG_CONFIG = pkg-config
INCS = -I\${X11INC} -I$XORG_DEPS/include/freetype2
LIBS = -static -L\${X11LIB} -lXft -lfontconfig -lXrender -lfreetype -lexpat -lX11 -lxcb -lXau -lz
STCPPFLAGS = -DVERSION=\"\${VERSION}\" -D_XOPEN_SOURCE=600
STCFLAGS = \${INCS} \${STCPPFLAGS} -Os -fno-stack-protector
STLDFLAGS = -static \${LIBS}
CC = i486-linux-musl-gcc
CONFIGMK

make clean && make
i486-linux-musl-strip st

mkdir -p "$BUILD_DIR/pkg/usr/bin"
cp st "$BUILD_DIR/pkg/usr/bin/"
chmod +x "$BUILD_DIR/pkg/usr/bin/st"
cd "$BUILD_DIR/pkg"
tar -czf "$REPO_DIR/st.pkg.tar.gz" .

rm -rf "$BUILD_DIR/pkg" "$BUILD_DIR/st-${ST_VER}"

echo "Created: $REPO_DIR/st.pkg.tar.gz ($(du -h "$REPO_DIR/st.pkg.tar.gz" | cut -f1))"
