#!/bin/bash
# build-dwm.sh - Generates dwm.pkg.tar.gz (Dynamic Window Manager)
# Requires xorg-deps from build-xfbdev.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
BUILD_DIR="$REPO_DIR/build"
TOOLCHAIN="/home/cesar/floppinux/i486-linux-musl-cross"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
export PATH="$TOOLCHAIN/bin:$PATH"
export CC=i486-linux-musl-gcc
export AR=i486-linux-musl-ar
export RANLIB=i486-linux-musl-ranlib

INSTALL_DIR="$BUILD_DIR/xorg-deps"

# Check if xorg-deps exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Error: xorg-deps not found. Run build-xfbdev.sh first."
    exit 1
fi

export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig:$INSTALL_DIR/share/pkgconfig"
export CFLAGS="-Os -fno-stack-protector -I$INSTALL_DIR/include"
export LDFLAGS="-static -L$INSTALL_DIR/lib"

# config.sub/config.guess
[ -f /tmp/config.sub ] || curl -sL -o /tmp/config.sub 'https://raw.githubusercontent.com/gcc-mirror/gcc/master/config.sub'
[ -f /tmp/config.guess ] || curl -sL -o /tmp/config.guess 'https://raw.githubusercontent.com/gcc-mirror/gcc/master/config.guess'

update_config() {
    [ -f config.sub ] && chmod +w config.sub && cp /tmp/config.sub . || true
    [ -f config.guess ] && chmod +w config.guess && cp /tmp/config.guess . || true
}

# ============================================
# Additional deps for dwm
# ============================================

# util-macros (xorg-macros)
if [ ! -f "$INSTALL_DIR/share/pkgconfig/xorg-macros.pc" ]; then
    echo "Building util-macros..."
    [ -f util-macros-1.20.1.tar.xz ] || curl -sL -o util-macros-1.20.1.tar.xz 'https://xorg.freedesktop.org/archive/individual/util/util-macros-1.20.1.tar.xz'
    rm -rf util-macros-1.20.1 && tar xf util-macros-1.20.1.tar.xz
    cd util-macros-1.20.1
    ./configure --prefix=$INSTALL_DIR
    make install
    cd .. && rm -rf util-macros-1.20.1
fi

# renderproto (if not present)
if [ ! -f "$INSTALL_DIR/lib/pkgconfig/renderproto.pc" ]; then
    echo "Building renderproto..."
    [ -f renderproto-0.11.1.tar.bz2 ] || curl -sL -o renderproto-0.11.1.tar.bz2 'https://xorg.freedesktop.org/archive/individual/proto/renderproto-0.11.1.tar.bz2'
    rm -rf renderproto-0.11.1 && tar xf renderproto-0.11.1.tar.bz2
    cd renderproto-0.11.1 && update_config
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR
    make install
    cd .. && rm -rf renderproto-0.11.1
fi

# xineramaproto
if [ ! -f "$INSTALL_DIR/lib/pkgconfig/xineramaproto.pc" ]; then
    echo "Building xineramaproto..."
    [ -f xineramaproto-1.2.1.tar.bz2 ] || curl -sL -o xineramaproto-1.2.1.tar.bz2 'https://xorg.freedesktop.org/archive/individual/proto/xineramaproto-1.2.1.tar.bz2'
    rm -rf xineramaproto-1.2.1 && tar xf xineramaproto-1.2.1.tar.bz2
    cd xineramaproto-1.2.1 && update_config
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR
    make install
    cd .. && rm -rf xineramaproto-1.2.1
fi

# libXext
if [ ! -f "$INSTALL_DIR/lib/libXext.a" ]; then
    echo "Building libXext..."
    [ -f libXext-1.3.6.tar.xz ] || curl -sL -o libXext-1.3.6.tar.xz 'https://xorg.freedesktop.org/archive/individual/lib/libXext-1.3.6.tar.xz'
    rm -rf libXext-1.3.6 && tar xf libXext-1.3.6.tar.xz
    cd libXext-1.3.6 && update_config
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR --disable-shared --enable-static --disable-malloc0returnsnull
    make -j$(nproc) && make install
    cd .. && rm -rf libXext-1.3.6
fi

# libXrender
if [ ! -f "$INSTALL_DIR/lib/libXrender.a" ]; then
    echo "Building libXrender..."
    [ -f libXrender-0.9.10.tar.gz ] || curl -sL -o libXrender-0.9.10.tar.gz 'https://xorg.freedesktop.org/archive/individual/lib/libXrender-0.9.10.tar.gz'
    rm -rf libXrender-0.9.10 && tar xf libXrender-0.9.10.tar.gz
    cd libXrender-0.9.10 && update_config
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR --disable-shared --enable-static --disable-malloc0returnsnull
    make -j$(nproc) && make install
    cd .. && rm -rf libXrender-0.9.10
fi

# expat (for fontconfig)
if [ ! -f "$INSTALL_DIR/lib/libexpat.a" ]; then
    echo "Building expat..."
    [ -f expat-2.6.4.tar.gz ] || curl -sL -o expat-2.6.4.tar.gz 'https://github.com/libexpat/libexpat/releases/download/R_2_6_4/expat-2.6.4.tar.gz'
    rm -rf expat-2.6.4 && tar xf expat-2.6.4.tar.gz
    cd expat-2.6.4 && update_config
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR --disable-shared --enable-static
    make -j$(nproc) && make install
    cd .. && rm -rf expat-2.6.4
fi

# fontconfig
if [ ! -f "$INSTALL_DIR/lib/libfontconfig.a" ]; then
    echo "Building fontconfig..."
    [ -f fontconfig-2.15.0.tar.xz ] || curl -sL -o fontconfig-2.15.0.tar.xz 'https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.15.0.tar.xz'
    rm -rf fontconfig-2.15.0 && tar xf fontconfig-2.15.0.tar.xz
    cd fontconfig-2.15.0 && update_config
    FREETYPE_CFLAGS="-I$INSTALL_DIR/include/freetype2" FREETYPE_LIBS="-L$INSTALL_DIR/lib -lfreetype" \
    EXPAT_CFLAGS="-I$INSTALL_DIR/include" EXPAT_LIBS="-L$INSTALL_DIR/lib -lexpat" \
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR --disable-shared --enable-static --disable-docs --disable-cache-build
    make -j$(nproc) && make install
    cd .. && rm -rf fontconfig-2.15.0
fi

# libXft
if [ ! -f "$INSTALL_DIR/lib/libXft.a" ]; then
    echo "Building libXft..."
    [ -f libXft-2.3.8.tar.xz ] || curl -sL -o libXft-2.3.8.tar.xz 'https://xorg.freedesktop.org/archive/individual/lib/libXft-2.3.8.tar.xz'
    rm -rf libXft-2.3.8 && tar xf libXft-2.3.8.tar.xz
    cd libXft-2.3.8 && update_config
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR --disable-shared --enable-static
    make -j$(nproc) && make install
    cd .. && rm -rf libXft-2.3.8
fi

# libXinerama
if [ ! -f "$INSTALL_DIR/lib/libXinerama.a" ]; then
    echo "Building libXinerama..."
    [ -f libXinerama-1.1.5.tar.xz ] || curl -sL -o libXinerama-1.1.5.tar.xz 'https://xorg.freedesktop.org/archive/individual/lib/libXinerama-1.1.5.tar.xz'
    rm -rf libXinerama-1.1.5 && tar xf libXinerama-1.1.5.tar.xz
    cd libXinerama-1.1.5 && update_config
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR --disable-shared --enable-static --disable-malloc0returnsnull
    make -j$(nproc) && make install
    cd .. && rm -rf libXinerama-1.1.5
fi

# ============================================
# Build dwm
# ============================================
echo "Building dwm..."
[ -f dwm-6.5.tar.gz ] || curl -sL -o dwm-6.5.tar.gz 'https://dl.suckless.org/dwm/dwm-6.5.tar.gz'
rm -rf dwm-6.5 && tar xzf dwm-6.5.tar.gz
cd dwm-6.5

cat > config.mk << EOF
VERSION = 6.5
PREFIX = /usr

X11INC = $INSTALL_DIR/include
X11LIB = $INSTALL_DIR/lib
FREETYPEINC = $INSTALL_DIR/include/freetype2

INCS = -I\${X11INC} -I\${FREETYPEINC}
LIBS = -L\${X11LIB} -lXft -lfontconfig -lfreetype -lXrender -lXinerama -lXext -lX11 -lxcb -lXau -lz -lexpat

CFLAGS = -std=c99 -D_GNU_SOURCE -pedantic -Wall -Os \${INCS} -DVERSION=\"\${VERSION}\" -DXINERAMA
LDFLAGS = -static \${LIBS}

CC = i486-linux-musl-gcc
EOF

make clean 2>/dev/null || true
make
i486-linux-musl-strip dwm

# Verify static
file dwm | grep -q "static" && echo "OK: Binary is static" || echo "WARNING: Binary may not be static"

# Create package
mkdir -p "$BUILD_DIR/pkg/usr/bin"
mkdir -p "$BUILD_DIR/pkg/etc/X11"
cp dwm "$BUILD_DIR/pkg/usr/bin/"
chmod +x "$BUILD_DIR/pkg/usr/bin/dwm"

cat > "$BUILD_DIR/pkg/etc/X11/xinitrc" << 'XINITRC'
#!/bin/sh
exec dwm
XINITRC
chmod +x "$BUILD_DIR/pkg/etc/X11/xinitrc"

cd "$BUILD_DIR/pkg"
tar czf "$REPO_DIR/dwm.pkg.tar.gz" .
cd ..
rm -rf "$BUILD_DIR/pkg" "$BUILD_DIR/dwm-6.5"

echo ""
echo "Created: $REPO_DIR/dwm.pkg.tar.gz ($(du -h "$REPO_DIR/dwm.pkg.tar.gz" | cut -f1))"
echo ""
echo "Usage: DISPLAY=:0 dwm"
