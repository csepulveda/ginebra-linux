#!/bin/bash
# build-dropbear.sh - Generates dropbear.pkg.tar.gz

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
BUILD_DIR="$REPO_DIR/build"
TOOLCHAIN="/home/cesar/floppinux/i486-linux-musl-cross"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

[ -f dropbear-2024.86.tar.bz2 ] || wget https://matt.ucc.asn.au/dropbear/releases/dropbear-2024.86.tar.bz2
rm -rf dropbear-2024.86
tar xjf dropbear-2024.86.tar.bz2
cd dropbear-2024.86

export PATH="$TOOLCHAIN/bin:$PATH"
export CC=i486-linux-musl-gcc
export AR=i486-linux-musl-ar
export RANLIB=i486-linux-musl-ranlib
export CFLAGS="-Os"
export LDFLAGS="-static"

./configure --host=i486-linux-musl \
    --disable-zlib --disable-pam --disable-syslog --disable-shadow \
    --disable-lastlog --disable-utmp --disable-utmpx --disable-wtmp \
    --disable-wtmpx --disable-loginfunc --disable-pututline --disable-pututxline

make -j$(nproc) PROGRAMS="dropbear dbclient dropbearkey scp" STATIC=1 LDFLAGS="-static"
i486-linux-musl-strip dropbear dbclient dropbearkey scp

mkdir -p "$BUILD_DIR/pkg/usr/bin" "$BUILD_DIR/pkg/usr/sbin" "$BUILD_DIR/pkg/etc/dropbear"
cp dropbear "$BUILD_DIR/pkg/usr/sbin/"
cp dbclient "$BUILD_DIR/pkg/usr/bin/ssh"
cp dropbearkey scp "$BUILD_DIR/pkg/usr/bin/"
chmod +x "$BUILD_DIR/pkg/usr/sbin/"* "$BUILD_DIR/pkg/usr/bin/"*
cd "$BUILD_DIR/pkg"
tar czf "$REPO_DIR/dropbear.pkg.tar.gz" .

rm -rf "$BUILD_DIR/pkg" "$BUILD_DIR/dropbear-2024.86"

echo "Created: $REPO_DIR/dropbear.pkg.tar.gz ($(du -h "$REPO_DIR/dropbear.pkg.tar.gz" | cut -f1))"
