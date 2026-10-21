#!/bin/bash
# build-tmux.sh - Generates tmux.pkg.tar.gz (static: tmux + libevent + ncurses)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
BUILD_DIR="$REPO_DIR/build"
TOOLCHAIN="${TOOLCHAIN:-$(cd "$SCRIPT_DIR/.." && pwd)/i486-linux-musl-cross}"

NCURSES_VER=6.4
LIBEVENT_VER=2.1.12-stable
TMUX_VER=3.5a

# Terminals compiled into ncurses (there is no terminfo database on Ginebra):
# outer terminals (linux console, st, xterm) plus screen/tmux
FALLBACKS=linux,vt100,xterm,xterm-256color,screen,tmux,st-256color,ansi,dumb

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

DEPS_DIR="$BUILD_DIR/tmux-deps"
rm -rf "$DEPS_DIR"

# ncurses (fallback.c is generated with the host compiler first)
[ -f ncurses-$NCURSES_VER.tar.gz ] || wget https://ftp.gnu.org/gnu/ncurses/ncurses-$NCURSES_VER.tar.gz
rm -rf ncurses-$NCURSES_VER
tar xzf ncurses-$NCURSES_VER.tar.gz

cd ncurses-$NCURSES_VER
unset CC AR RANLIB CFLAGS LDFLAGS
./configure --with-fallbacks=$FALLBACKS
make -C include
make -C ncurses fallback.c
cp ncurses/fallback.c "$BUILD_DIR/tmux-fallback.c"
make distclean

export PATH="$TOOLCHAIN/bin:$PATH"
export CC=i486-linux-musl-gcc
export AR=i486-linux-musl-ar
export RANLIB=i486-linux-musl-ranlib

./configure \
    --host=i486-linux-musl \
    --prefix="$DEPS_DIR" \
    --without-cxx --without-cxx-binding --without-ada \
    --without-manpages --without-progs --without-tests \
    --disable-shared --enable-static \
    --without-debug --without-profile --disable-stripping \
    --disable-widec --disable-database \
    --with-fallbacks=$FALLBACKS \
    CFLAGS="-Os"

cp "$BUILD_DIR/tmux-fallback.c" ncurses/fallback.c
make -j$(nproc)
make install
cd "$BUILD_DIR"

# libevent (no openssl, no threads: tmux uses neither)
[ -f libevent-$LIBEVENT_VER.tar.gz ] || wget https://github.com/libevent/libevent/releases/download/release-$LIBEVENT_VER/libevent-$LIBEVENT_VER.tar.gz
rm -rf libevent-$LIBEVENT_VER
tar xzf libevent-$LIBEVENT_VER.tar.gz
cd libevent-$LIBEVENT_VER
./configure \
    --host=i486-linux-musl \
    --prefix="$DEPS_DIR" \
    --disable-shared --enable-static \
    --disable-openssl --disable-thread-support --disable-debug-mode \
    --disable-libevent-regress --disable-samples --disable-benchmark \
    CFLAGS="-Os"
make -j$(nproc)
make install
cd "$BUILD_DIR"

# tmux
[ -f tmux-$TMUX_VER.tar.gz ] || wget https://github.com/tmux/tmux/releases/download/$TMUX_VER/tmux-$TMUX_VER.tar.gz
rm -rf tmux-$TMUX_VER
tar xzf tmux-$TMUX_VER.tar.gz
cd tmux-$TMUX_VER
./configure \
    --host=i486-linux-musl \
    --prefix=/usr \
    --enable-static \
    --disable-utf8proc \
    CFLAGS="-Os -I$DEPS_DIR/include -I$DEPS_DIR/include/ncurses" \
    LDFLAGS="-L$DEPS_DIR/lib" \
    PKG_CONFIG_LIBDIR="$DEPS_DIR/lib/pkgconfig" \
    LIBEVENT_CFLAGS="-I$DEPS_DIR/include" \
    LIBEVENT_LIBS="-L$DEPS_DIR/lib -levent_core" \
    LIBTINFO_CFLAGS="-I$DEPS_DIR/include -I$DEPS_DIR/include/ncurses" \
    LIBTINFO_LIBS="-L$DEPS_DIR/lib -lncurses" \
    LIBNCURSES_CFLAGS="-I$DEPS_DIR/include -I$DEPS_DIR/include/ncurses" \
    LIBNCURSES_LIBS="-L$DEPS_DIR/lib -lncurses"
make -j$(nproc)
i486-linux-musl-strip tmux

# Create package
rm -rf "$BUILD_DIR/pkg"
mkdir -p "$BUILD_DIR/pkg/usr/bin" "$BUILD_DIR/pkg/etc"
cp tmux "$BUILD_DIR/pkg/usr/bin/"
chmod +x "$BUILD_DIR/pkg/usr/bin/tmux"
# The other packages (htop, vim, less...) only know linux/vt100/xterm/ansi, so the
# panes use TERM=xterm instead of tmux's default (screen), which they can't open
cat > "$BUILD_DIR/pkg/etc/tmux.conf" << 'EOF'
# Ginebra Linux - /etc/tmux.conf
set -g default-terminal "xterm"
set -g history-limit 1000
set -sg escape-time 10
EOF
cd "$BUILD_DIR/pkg"
tar czf "$REPO_DIR/tmux.pkg.tar.gz" .

# Cleanup
rm -rf "$BUILD_DIR/pkg" "$BUILD_DIR/ncurses-$NCURSES_VER" "$DEPS_DIR"
rm -rf "$BUILD_DIR/libevent-$LIBEVENT_VER" "$BUILD_DIR/tmux-$TMUX_VER" "$BUILD_DIR/tmux-fallback.c"

echo ""
echo "Created: $REPO_DIR/tmux.pkg.tar.gz ($(du -h "$REPO_DIR/tmux.pkg.tar.gz" | cut -f1))"
