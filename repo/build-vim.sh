#!/bin/bash
# build-vim.sh - Generates vim.pkg.tar.gz

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

[ -f vim-9.1.tar.gz ] || wget https://github.com/vim/vim/archive/refs/tags/v9.1.0000.tar.gz -O vim-9.1.tar.gz
rm -rf vim-9.1.0000
tar xzf vim-9.1.tar.gz
cd vim-9.1.0000

cat > src/auto/config.cache << 'CACHE'
vim_cv_toupper_broken=no
vim_cv_terminfo=yes
vim_cv_tgetent=zero
vim_cv_getcwd_broken=no
vim_cv_stat_ignores_slash=yes
vim_cv_memmove_handles_overlap=yes
CACHE

./configure \
    --host=i486-linux-musl --with-tlib=ncurses \
    --disable-gui --disable-gtktest --disable-xim --without-x \
    --disable-netbeans --disable-channel --disable-terminal \
    --disable-gpm --disable-sysmouse --disable-nls --enable-multibyte \
    --disable-canberra --disable-libsodium \
    CFLAGS="-Os -I${NCURSES_DIR}/include" \
    LDFLAGS="-static -L${NCURSES_DIR}/lib" LIBS="-lncurses"

make -j$(nproc) LDFLAGS="-static -L${NCURSES_DIR}/lib"
i486-linux-musl-strip src/vim

mkdir -p "$BUILD_DIR/pkg/usr/bin"
cp src/vim "$BUILD_DIR/pkg/usr/bin/"
chmod +x "$BUILD_DIR/pkg/usr/bin/vim"
cd "$BUILD_DIR/pkg"
tar czf "$REPO_DIR/vim.pkg.tar.gz" .

rm -rf "$BUILD_DIR/pkg" "$BUILD_DIR/ncurses-6.4" "$BUILD_DIR/ncurses-install"
rm -rf "$BUILD_DIR/vim-9.1.0000" "$BUILD_DIR/fallback-generated.c"

echo "Created: $REPO_DIR/vim.pkg.tar.gz ($(du -h "$REPO_DIR/vim.pkg.tar.gz" | cut -f1))"
