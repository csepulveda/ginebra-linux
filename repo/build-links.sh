#!/bin/bash
# build-links.sh

wget http://links.twibright.com/download/links-2.30.tar.gz
tar xzf links-2.30.tar.gz
cd links-2.30

export PATH="$PWD/../i486-linux-musl-cross/bin:$PATH"
export CC=i486-linux-musl-gcc
export AR=i486-linux-musl-ar
export RANLIB=i486-linux-musl-ranlib
export CFLAGS="-Os"
export LDFLAGS="-static"

./configure \
    --host=i486-linux-musl \
    --disable-graphics \
    --without-x \
    --without-fb \
    --without-directfb \
    --without-svgalib \
    --without-libjpeg \
    --without-libtiff \
    --without-libpng \
    --without-openssl \
    --without-gpm \
    --enable-static

make -j$(nproc)
i486-linux-musl-strip links

cp links ../
cd ..

rm -rf links-2.30.tar.gz links-2.30

echo "Done! Binary: links ($(du -h links | cut -f1))"
