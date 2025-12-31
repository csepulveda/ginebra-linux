#!/bin/bash
# build-strace.sh - Generates strace.pkg.tar.gz

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
BUILD_DIR="$REPO_DIR/build"
TOOLCHAIN="/home/cesar/floppinux/i486-linux-musl-cross"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

export PATH="$TOOLCHAIN/bin:$PATH"
export CC=i486-linux-musl-gcc

[ -f strace-6.11.tar.xz ] || wget https://github.com/strace/strace/releases/download/v6.11/strace-6.11.tar.xz
rm -rf strace-6.11
tar xf strace-6.11.tar.xz
cd strace-6.11

./configure --host=i486-linux-musl --enable-static CFLAGS="-Os" LDFLAGS="-static"
make -j$(nproc)
i486-linux-musl-strip src/strace

mkdir -p "$BUILD_DIR/pkg/usr/bin"
cp src/strace "$BUILD_DIR/pkg/usr/bin/"
chmod +x "$BUILD_DIR/pkg/usr/bin/strace"
cd "$BUILD_DIR/pkg"
tar czf "$REPO_DIR/strace.pkg.tar.gz" .

rm -rf "$BUILD_DIR/pkg" "$BUILD_DIR/strace-6.11"

echo "Created: $REPO_DIR/strace.pkg.tar.gz ($(du -h "$REPO_DIR/strace.pkg.tar.gz" | cut -f1))"
