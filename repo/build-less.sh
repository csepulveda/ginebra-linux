#!/bin/bash
# build-less.sh - Generates less.pkg.tar.gz

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
BUILD_DIR="$REPO_DIR/build"
TOOLCHAIN="/home/cesar/floppinux/i486-linux-musl-cross"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

NCURSES_DIR="$BUILD_DIR/ncurses-install"

[ -f ncurses-6.4.tar.gz ] || wget https://ftp.gnu.org/gnu/ncurses/ncurses-6.4.tar.gz
rm -rf ncurses-6.4
tar xzf ncurses-6.4.tar.gz

cd ncurses-6.4
unset CC AR RANLIB CFLAGS LDFLAGS
./configure --with-fallbacks=linux,vt100,xterm,xterm-256color,ansi,dumb
make -C include
make -C ncurses fallback.c
cp ncurses/fallback.c "$BUILD_DIR/fallback-generated.c"
make distclean

export PATH="$TOOLCHAIN/bin:$PATH"
export CC=i486-linux-musl-gcc
export AR=i486-linux-musl-ar
export RANLIB=i486-linux-musl-ranlib

./configure \
    --host=i486-linux-musl --prefix="$NCURSES_DIR" \
    --without-cxx --without-cxx-binding --without-ada \
    --without-manpages --without-progs --without-tests \
    --disable-shared --enable-static --without-debug --without-profile \
    --disable-stripping --disable-widec --disable-database \
    --with-fallbacks=linux,vt100,xterm,xterm-256color,ansi,dumb

cp "$BUILD_DIR/fallback-generated.c" ncurses/fallback.c
make -j$(nproc)
make install
cd "$BUILD_DIR"

[ -f less-661.tar.gz ] || wget https://www.greenwoodsoftware.com/less/less-661.tar.gz
rm -rf less-661
tar xzf less-661.tar.gz
cd less-661

export CFLAGS="-Os -I${NCURSES_DIR}/include"
export LDFLAGS="-static -L${NCURSES_DIR}/lib"
export LIBS="-lncurses"

./configure --host=i486-linux-musl
make -j$(nproc) LDFLAGS="-static -L${NCURSES_DIR}/lib"
i486-linux-musl-strip less lesskey lessecho 2>/dev/null || true

mkdir -p "$BUILD_DIR/pkg/usr/bin"
cp less "$BUILD_DIR/pkg/usr/bin/"
[ -f lesskey ] && cp lesskey "$BUILD_DIR/pkg/usr/bin/"
[ -f lessecho ] && cp lessecho "$BUILD_DIR/pkg/usr/bin/"
chmod +x "$BUILD_DIR/pkg/usr/bin/"*
cd "$BUILD_DIR/pkg"
tar czf "$REPO_DIR/less.pkg.tar.gz" .

rm -rf "$BUILD_DIR/pkg" "$BUILD_DIR/ncurses-6.4" "$BUILD_DIR/ncurses-install"
rm -rf "$BUILD_DIR/less-661" "$BUILD_DIR/fallback-generated.c"

echo "Created: $REPO_DIR/less.pkg.tar.gz ($(du -h "$REPO_DIR/less.pkg.tar.gz" | cut -f1))"
