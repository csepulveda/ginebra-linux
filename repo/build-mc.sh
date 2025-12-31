#!/bin/bash
# build-mc.sh - Generates mc.pkg.tar.gz (Midnight Commander)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
BUILD_DIR="$REPO_DIR/build"
TOOLCHAIN="/home/cesar/floppinux/i486-linux-musl-cross"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

export PATH="$TOOLCHAIN/bin:$PATH"
INSTALL_DIR="$BUILD_DIR/mc-deps"
mkdir -p "$INSTALL_DIR"

echo "[1/5] Building libffi..."
[ -f libffi-3.4.6.tar.gz ] || wget https://github.com/libffi/libffi/releases/download/v3.4.6/libffi-3.4.6.tar.gz
rm -rf libffi-3.4.6
tar xzf libffi-3.4.6.tar.gz
cd libffi-3.4.6
CC=i486-linux-musl-gcc AR=i486-linux-musl-ar RANLIB=i486-linux-musl-ranlib CFLAGS="-Os" \
./configure --host=i486-linux-musl --prefix="$INSTALL_DIR" --disable-shared --enable-static
make -j$(nproc) && make install
cd "$BUILD_DIR"

echo "[2/5] Building pcre2..."
[ -f pcre2-10.44.tar.gz ] || wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.44/pcre2-10.44.tar.gz
rm -rf pcre2-10.44
tar xzf pcre2-10.44.tar.gz
cd pcre2-10.44
CC=i486-linux-musl-gcc AR=i486-linux-musl-ar RANLIB=i486-linux-musl-ranlib CFLAGS="-Os" \
./configure --host=i486-linux-musl --prefix="$INSTALL_DIR" --disable-shared --enable-static --disable-cpp
make -j$(nproc) && make install
cd "$BUILD_DIR"

echo "[3/5] Building glib2..."
[ -f glib-2.78.6.tar.xz ] || wget https://download.gnome.org/sources/glib/2.78/glib-2.78.6.tar.xz
rm -rf glib-2.78.6
tar xf glib-2.78.6.tar.xz
cd glib-2.78.6

cat > cross-file.txt << CROSS
[binaries]
c = 'i486-linux-musl-gcc'
ar = 'i486-linux-musl-ar'
strip = 'i486-linux-musl-strip'
pkg-config = 'pkg-config'
[host_machine]
system = 'linux'
cpu_family = 'x86'
cpu = 'i486'
endian = 'little'
[built-in options]
c_args = ['-Os']
c_link_args = ['-static']
default_library = 'static'
CROSS

export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig"
export PKG_CONFIG_LIBDIR="$INSTALL_DIR/lib/pkgconfig"

meson setup build --cross-file cross-file.txt --prefix="$INSTALL_DIR" --default-library=static \
    -Dtests=false -Dnls=disabled -Dxattr=false -Dlibmount=disabled -Dglib_debug=disabled
ninja -C build && ninja -C build install
cd "$BUILD_DIR"

echo "[4/5] Building slang..."
[ -f slang-2.3.3.tar.bz2 ] || wget https://www.jedsoft.org/releases/slang/slang-2.3.3.tar.bz2
rm -rf slang-2.3.3
tar xjf slang-2.3.3.tar.bz2
cd slang-2.3.3
CC=i486-linux-musl-gcc AR=i486-linux-musl-ar RANLIB=i486-linux-musl-ranlib CFLAGS="-Os" \
./configure --host=i486-linux-musl --prefix="$INSTALL_DIR" --disable-shared --enable-static \
    --without-png --without-pcre --without-onig --without-z
make -j$(nproc) static && make install-static
cd "$BUILD_DIR"

echo "[5/5] Building mc..."
[ -f mc-4.8.31.tar.xz ] || wget --no-check-certificate https://ftp.midnight-commander.org/mc-4.8.31.tar.xz
rm -rf mc-4.8.31
tar xf mc-4.8.31.tar.xz
cd mc-4.8.31

export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig:$INSTALL_DIR/lib64/pkgconfig"
export CFLAGS="-Os -I$INSTALL_DIR/include -I$INSTALL_DIR/include/glib-2.0 -I$INSTALL_DIR/lib/glib-2.0/include"
export LDFLAGS="-static -L$INSTALL_DIR/lib -L$INSTALL_DIR/lib64"
export CC=i486-linux-musl-gcc AR=i486-linux-musl-ar RANLIB=i486-linux-musl-ranlib

./configure --host=i486-linux-musl --prefix=/usr --sysconfdir=/etc \
    --disable-shared --enable-static --with-screen=slang \
    --with-slang-includes="$INSTALL_DIR/include" --with-slang-libs="$INSTALL_DIR/lib" \
    --without-x --without-gpm-mouse --disable-nls \
    --disable-vfs-sftp --disable-vfs-extfs --disable-vfs-fish --disable-vfs-sfs --disable-vfs-smb \
    --disable-doxygen-doc --disable-background --disable-largefile \
    GLIB_CFLAGS="-I$INSTALL_DIR/include/glib-2.0 -I$INSTALL_DIR/lib/glib-2.0/include" \
    GLIB_LIBS="-L$INSTALL_DIR/lib -lglib-2.0 -lpcre2-8 -lffi" \
    SLANG_CFLAGS="-I$INSTALL_DIR/include" SLANG_LIBS="-L$INSTALL_DIR/lib -lslang"

sed -i 's/^link_all_deplibs=no/link_all_deplibs=yes/' libtool
sed -i 's/^build_libtool_libs=yes/build_libtool_libs=no/' libtool
make -j$(nproc) LDFLAGS="-all-static -L$INSTALL_DIR/lib"
i486-linux-musl-strip src/mc

mkdir -p "$BUILD_DIR/pkg/usr/bin" "$BUILD_DIR/pkg/etc/mc"
cp src/mc "$BUILD_DIR/pkg/usr/bin/"
cp misc/mc.ext.ini misc/filehighlight.ini "$BUILD_DIR/pkg/etc/mc/" 2>/dev/null || true
cd "$BUILD_DIR/pkg/usr/bin" && ln -s mc mcedit && ln -s mc mcview
chmod +x "$BUILD_DIR/pkg/usr/bin/mc"
cd "$BUILD_DIR/pkg"
tar czf "$REPO_DIR/mc.pkg.tar.gz" .

rm -rf "$BUILD_DIR/pkg" "$BUILD_DIR/libffi-3.4.6" "$BUILD_DIR/pcre2-10.44" \
    "$BUILD_DIR/glib-2.78.6" "$BUILD_DIR/slang-2.3.3" "$BUILD_DIR/mc-4.8.31" "$BUILD_DIR/mc-deps"

echo "Created: $REPO_DIR/mc.pkg.tar.gz ($(du -h "$REPO_DIR/mc.pkg.tar.gz" | cut -f1))"
