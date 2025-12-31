#!/bin/bash
# build-file.sh - Generates file.pkg.tar.gz

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
BUILD_DIR="$REPO_DIR/build"
TOOLCHAIN="/home/cesar/floppinux/i486-linux-musl-cross"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

[ -f file-5.45.tar.gz ] || wget https://astron.com/pub/file/file-5.45.tar.gz
rm -rf file-5.45
tar xzf file-5.45.tar.gz

# Build native version for magic.mgc
cd file-5.45
unset CC AR RANLIB CFLAGS LDFLAGS
./configure
make -j$(nproc)
cp magic/magic.mgc "$BUILD_DIR/magic.mgc"
make distclean

# Cross-compile
export PATH="$TOOLCHAIN/bin:$PATH"
export CC=i486-linux-musl-gcc
export AR=i486-linux-musl-ar
export RANLIB=i486-linux-musl-ranlib
export CFLAGS="-Os"
export LDFLAGS="-static"

./configure --host=i486-linux-musl --disable-shared --enable-static
sed -i 's/^link_all_deplibs=no/link_all_deplibs=yes/' libtool
sed -i 's/^build_libtool_libs=yes/build_libtool_libs=no/' libtool
cp "$BUILD_DIR/magic.mgc" magic/magic.mgc
make -j$(nproc) LDFLAGS="-all-static" || true

if [ -f src/.libs/file ]; then
    cp src/.libs/file "$BUILD_DIR/file-bin"
else
    cp src/file "$BUILD_DIR/file-bin"
fi
i486-linux-musl-strip "$BUILD_DIR/file-bin"
cd "$BUILD_DIR"

mkdir -p "$BUILD_DIR/pkg/usr/bin" "$BUILD_DIR/pkg/usr/share/misc"
cp file-bin "$BUILD_DIR/pkg/usr/bin/file"
cp magic.mgc "$BUILD_DIR/pkg/usr/share/misc/magic.mgc"
chmod +x "$BUILD_DIR/pkg/usr/bin/file"
cd "$BUILD_DIR/pkg"
tar czf "$REPO_DIR/file.pkg.tar.gz" .

rm -rf "$BUILD_DIR/pkg" "$BUILD_DIR/file-5.45" "$BUILD_DIR/file-bin" "$BUILD_DIR/magic.mgc"

echo "Created: $REPO_DIR/file.pkg.tar.gz ($(du -h "$REPO_DIR/file.pkg.tar.gz" | cut -f1))"
