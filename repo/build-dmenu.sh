#!/bin/bash
# build-dmenu.sh - Generates dmenu.pkg.tar.gz

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
export PKG_CONFIG_PATH="$XORG_DEPS/lib/pkgconfig"
export CFLAGS="-Os -fno-stack-protector -I$XORG_DEPS/include -I$XORG_DEPS/include/freetype2"
export LDFLAGS="-static -L$XORG_DEPS/lib"

DMENU_VER="5.3"
[ -f "dmenu-${DMENU_VER}.tar.gz" ] || curl -LO "https://dl.suckless.org/tools/dmenu-${DMENU_VER}.tar.gz"
rm -rf "dmenu-${DMENU_VER}"
tar -xzf "dmenu-${DMENU_VER}.tar.gz"
cd "dmenu-${DMENU_VER}"

cat > config.mk << CONFIGMK
VERSION = 5.3
PREFIX = /usr
X11INC = $XORG_DEPS/include
X11LIB = $XORG_DEPS/lib
FREETYPEINC = $XORG_DEPS/include/freetype2
INCS = -I\${X11INC} -I\${FREETYPEINC}
LIBS = -static -L\${X11LIB} -lXft -lfontconfig -lXrender -lfreetype -lexpat -lXinerama -lX11 -lxcb -lXau -lz
CPPFLAGS = -D_DEFAULT_SOURCE -D_BSD_SOURCE -D_XOPEN_SOURCE=700 -D_POSIX_C_SOURCE=200809L -DVERSION=\"\${VERSION}\"
CFLAGS = -std=c99 -pedantic -Wall -Os -fno-stack-protector \${INCS} \${CPPFLAGS}
LDFLAGS = -static \${LIBS}
CC = i486-linux-musl-gcc
CONFIGMK

make clean && make
i486-linux-musl-strip dmenu stest 2>/dev/null || true

mkdir -p "$BUILD_DIR/pkg/usr/bin"
cp dmenu dmenu_path dmenu_run stest "$BUILD_DIR/pkg/usr/bin/"
chmod +x "$BUILD_DIR/pkg/usr/bin/"*
cd "$BUILD_DIR/pkg"
tar -czf "$REPO_DIR/dmenu.pkg.tar.gz" .

rm -rf "$BUILD_DIR/pkg" "$BUILD_DIR/dmenu-${DMENU_VER}"

echo "Created: $REPO_DIR/dmenu.pkg.tar.gz ($(du -h "$REPO_DIR/dmenu.pkg.tar.gz" | cut -f1))"
