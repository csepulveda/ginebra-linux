#!/bin/bash
# build-nc.sh - Generates nc.pkg.tar.gz (GNU Netcat)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
BUILD_DIR="$REPO_DIR/build"
TOOLCHAIN="/home/cesar/floppinux/i486-linux-musl-cross"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

[ -f netcat-0.7.1.tar.gz ] || wget https://sourceforge.net/projects/netcat/files/netcat/0.7.1/netcat-0.7.1.tar.gz/download -O netcat-0.7.1.tar.gz
rm -rf netcat-0.7.1
tar xzf netcat-0.7.1.tar.gz
cd netcat-0.7.1

curl -sL -o config.sub "https://github.com/gcc-mirror/gcc/raw/master/config.sub"
curl -sL -o config.guess "https://github.com/gcc-mirror/gcc/raw/master/config.guess"

export PATH="$TOOLCHAIN/bin:$PATH"
export CC=i486-linux-musl-gcc
export AR=i486-linux-musl-ar
export RANLIB=i486-linux-musl-ranlib
export CFLAGS="-Os"
export LDFLAGS="-static"

./configure --host=i486-linux-musl
make -j$(nproc) LDFLAGS="-static"
i486-linux-musl-strip src/netcat

mkdir -p "$BUILD_DIR/pkg/usr/bin"
cp src/netcat "$BUILD_DIR/pkg/usr/bin/nc"
chmod +x "$BUILD_DIR/pkg/usr/bin/nc"
cd "$BUILD_DIR/pkg"
tar czf "$REPO_DIR/nc.pkg.tar.gz" .

rm -rf "$BUILD_DIR/pkg" "$BUILD_DIR/netcat-0.7.1"

echo "Created: $REPO_DIR/nc.pkg.tar.gz ($(du -h "$REPO_DIR/nc.pkg.tar.gz" | cut -f1))"
