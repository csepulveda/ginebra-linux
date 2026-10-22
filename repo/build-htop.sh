#!/bin/bash
# build-htop.sh - Generates htop.pkg.tar.gz

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
BUILD_DIR="$REPO_DIR/build"
TOOLCHAIN="${TOOLCHAIN:-$(cd "$SCRIPT_DIR/.." && pwd)/i486-linux-musl-cross}"

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
    --host=i486-linux-musl \
    --prefix="$NCURSES_DIR" \
    --without-cxx --without-cxx-binding --without-ada \
    --without-manpages --without-progs --without-tests \
    --disable-shared --enable-static \
    --without-debug --without-profile --disable-stripping \
    --disable-widec --disable-database \
    --with-fallbacks=linux,vt100,xterm,xterm-256color,ansi,dumb

cp "$BUILD_DIR/fallback-generated.c" ncurses/fallback.c
make -j$(nproc)
make install
cd "$BUILD_DIR"

[ -f htop-3.3.0.tar.xz ] || wget https://github.com/htop-dev/htop/releases/download/3.3.0/htop-3.3.0.tar.xz
rm -rf htop-3.3.0
tar xf htop-3.3.0.tar.xz
cd htop-3.3.0

./configure \
    --host=i486-linux-musl \
    --disable-unicode --disable-hwloc --disable-sensors --disable-capabilities \
    --enable-static \
    CFLAGS="-Os -I${NCURSES_DIR}/include" \
    LDFLAGS="-static -L${NCURSES_DIR}/lib" \
    CPPFLAGS="-I${NCURSES_DIR}/include" \
    LIBS="-lncurses"

make -j$(nproc)
i486-linux-musl-strip htop

# Create package
mkdir -p "$BUILD_DIR/pkg/usr/bin"
cp htop "$BUILD_DIR/pkg/usr/bin/"
chmod +x "$BUILD_DIR/pkg/usr/bin/htop"
cd "$BUILD_DIR/pkg"
tar czf "$REPO_DIR/htop.pkg.tar.gz" .

# Cleanup
rm -rf "$BUILD_DIR/pkg" "$BUILD_DIR/ncurses-6.4" "$BUILD_DIR/ncurses-install"
rm -rf "$BUILD_DIR/htop-3.3.0" "$BUILD_DIR/fallback-generated.c"

echo ""
echo "Created: $REPO_DIR/htop.pkg.tar.gz ($(du -h "$REPO_DIR/htop.pkg.tar.gz" | cut -f1))"
