#!/bin/bash
# build-htop.sh

set -e

NCURSES_DIR="$PWD/ncurses-install"

wget https://ftp.gnu.org/gnu/ncurses/ncurses-6.4.tar.gz
tar xzf ncurses-6.4.tar.gz

cd ncurses-6.4

unset CC AR RANLIB CFLAGS LDFLAGS

./configure --with-fallbacks=linux,vt100,xterm,xterm-256color,ansi,dumb
make -C include
make -C ncurses fallback.c
cp ncurses/fallback.c ../fallback-generated.c
make distclean
cd ..

cd ncurses-6.4

export PATH="$PWD/../i486-linux-musl-cross/bin:$PATH"
export CC=i486-linux-musl-gcc
export AR=i486-linux-musl-ar
export RANLIB=i486-linux-musl-ranlib

./configure \
    --host=i486-linux-musl \
    --prefix=$NCURSES_DIR \
    --without-cxx \
    --without-cxx-binding \
    --without-ada \
    --without-manpages \
    --without-progs \
    --without-tests \
    --disable-shared \
    --enable-static \
    --without-debug \
    --without-profile \
    --disable-stripping \
    --disable-widec \
    --disable-database \
    --with-fallbacks=linux,vt100,xterm,xterm-256color,ansi,dumb

cp ../fallback-generated.c ncurses/fallback.c

make -j$(nproc)
make install
cd ..

wget https://github.com/htop-dev/htop/releases/download/3.3.0/htop-3.3.0.tar.xz
tar xf htop-3.3.0.tar.xz
cd htop-3.3.0

./configure \
    --host=i486-linux-musl \
    --disable-unicode \
    --disable-hwloc \
    --disable-sensors \
    --disable-capabilities \
    --enable-static \
    CFLAGS="-Os -I${NCURSES_DIR}/include" \
    LDFLAGS="-static -L${NCURSES_DIR}/lib" \
    CPPFLAGS="-I${NCURSES_DIR}/include" \
    LIBS="-lncurses"

make -j$(nproc)
i486-linux-musl-strip htop

cp htop ../
cd ..

rm -rf ncurses-6.4.tar.gz ncurses-6.4 ncurses-install
rm -rf htop-3.3.0.tar.xz htop-3.3.0
rm -f fallback-generated.c

file htop
ls -lh htop

echo ""
