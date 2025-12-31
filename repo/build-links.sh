#!/bin/bash
# build-links.sh - Generates links.pkg.tar.gz (with SSL support)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
BUILD_DIR="$REPO_DIR/build"
TOOLCHAIN="/home/cesar/floppinux/i486-linux-musl-cross"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

export PATH="$TOOLCHAIN/bin:$PATH"
INSTALL_DIR="$BUILD_DIR/links-deps"
mkdir -p "$INSTALL_DIR"

echo "[1/3] Building OpenSSL..."
[ -f openssl-1.1.1w.tar.gz ] || wget https://www.openssl.org/source/openssl-1.1.1w.tar.gz
rm -rf openssl-1.1.1w
tar xzf openssl-1.1.1w.tar.gz
cd openssl-1.1.1w

unset CC AR RANLIB
./Configure linux-x86 --prefix="$INSTALL_DIR" --openssldir="$INSTALL_DIR/ssl" \
    no-shared no-async no-engine no-dso -Os --cross-compile-prefix=i486-linux-musl-
make -j$(nproc)
make install_sw
cd "$BUILD_DIR"

export CC=i486-linux-musl-gcc
export AR=i486-linux-musl-ar
export RANLIB=i486-linux-musl-ranlib

echo "[2/3] Downloading CA certificates..."
[ -f ca-certificates.crt ] || wget https://curl.se/ca/cacert.pem -O ca-certificates.crt

echo "[3/3] Building links..."
[ -f links-2.30.tar.gz ] || wget http://links.twibright.com/download/links-2.30.tar.gz
rm -rf links-2.30
tar xzf links-2.30.tar.gz
cd links-2.30

export CFLAGS="-Os -I$INSTALL_DIR/include"
export LDFLAGS="-static -L$INSTALL_DIR/lib"
export LIBS="-lssl -lcrypto"

./configure --host=i486-linux-musl \
    --disable-graphics --without-x --without-fb --without-directfb \
    --without-svgalib --without-libjpeg --without-libtiff --without-libpng \
    --with-ssl="$INSTALL_DIR" --without-gpm --enable-static

make -j$(nproc) LDFLAGS="-static -L$INSTALL_DIR/lib" LIBS="-lssl -lcrypto"
i486-linux-musl-strip links

mkdir -p "$BUILD_DIR/pkg/usr/bin" "$BUILD_DIR/pkg/etc/ssl/certs"
cp links "$BUILD_DIR/pkg/usr/bin/"
cp "$BUILD_DIR/ca-certificates.crt" "$BUILD_DIR/pkg/etc/ssl/certs/"
chmod +x "$BUILD_DIR/pkg/usr/bin/links"
cd "$BUILD_DIR/pkg"
tar czf "$REPO_DIR/links.pkg.tar.gz" .

rm -rf "$BUILD_DIR/pkg" "$BUILD_DIR/openssl-1.1.1w" "$BUILD_DIR/links-2.30" "$BUILD_DIR/links-deps"

echo "Created: $REPO_DIR/links.pkg.tar.gz ($(du -h "$REPO_DIR/links.pkg.tar.gz" | cut -f1))"
