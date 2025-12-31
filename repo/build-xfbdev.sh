#!/bin/bash
# build-xfbdev.sh - Build Xfbdev with full input support for i486-musl
# Includes: Xfbdev, xkbcomp, xkeyboard-config, Liberation fonts
set -ex

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
BUILD_DIR="$REPO_DIR/build"
PATCHES_DIR="$REPO_DIR/patches"
FLOPPINUX_DIR="/home/cesar/floppinux"
TOOLCHAIN="$FLOPPINUX_DIR/i486-linux-musl-cross"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

export PATH="$TOOLCHAIN/bin:$PATH"
export CC=i486-linux-musl-gcc
export AR=i486-linux-musl-ar
export RANLIB=i486-linux-musl-ranlib

INSTALL_DIR="$BUILD_DIR/xorg-deps"
PKG_DIR="$BUILD_DIR/pkg-xfbdev"

mkdir -p $INSTALL_DIR $PKG_DIR/usr/bin $PKG_DIR/usr/share/X11/xkb $PKG_DIR/usr/share/fonts/TTF

# Use only our pkg-config path, ignore system packages
export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig:$INSTALL_DIR/share/pkgconfig"
export PKG_CONFIG_LIBDIR="$INSTALL_DIR/lib/pkgconfig:$INSTALL_DIR/share/pkgconfig"
export CFLAGS="-Os -fno-stack-protector -I$INSTALL_DIR/include"
export LDFLAGS="-static -L$INSTALL_DIR/lib"

# Download config.sub/config.guess from GitHub (savannah.gnu.org times out)
[ -f /tmp/config.sub ] || curl -sL -o /tmp/config.sub 'https://raw.githubusercontent.com/gcc-mirror/gcc/master/config.sub'
[ -f /tmp/config.guess ] || curl -sL -o /tmp/config.guess 'https://raw.githubusercontent.com/gcc-mirror/gcc/master/config.guess'

update_config() {
    [ -f config.sub ] && chmod +w config.sub && cp /tmp/config.sub . || true
    [ -f config.guess ] && chmod +w config.guess && cp /tmp/config.guess . || true
}

# Download sources
echo "=== Downloading sources ==="
BASE_URL="https://xorg.freedesktop.org/archive/individual"
[ -f xproto-7.0.31.tar.bz2 ] || curl -sL -o xproto-7.0.31.tar.bz2 "$BASE_URL/proto/xproto-7.0.31.tar.bz2"
[ -f xextproto-7.3.0.tar.bz2 ] || curl -sL -o xextproto-7.3.0.tar.bz2 "$BASE_URL/proto/xextproto-7.3.0.tar.bz2"
[ -f inputproto-2.3.2.tar.bz2 ] || curl -sL -o inputproto-2.3.2.tar.bz2 "$BASE_URL/proto/inputproto-2.3.2.tar.bz2"
[ -f kbproto-1.0.7.tar.bz2 ] || curl -sL -o kbproto-1.0.7.tar.bz2 "$BASE_URL/proto/kbproto-1.0.7.tar.bz2"
[ -f renderproto-0.11.1.tar.bz2 ] || curl -sL -o renderproto-0.11.1.tar.bz2 "$BASE_URL/proto/renderproto-0.11.1.tar.bz2"
[ -f randrproto-1.5.0.tar.bz2 ] || curl -sL -o randrproto-1.5.0.tar.bz2 "$BASE_URL/proto/randrproto-1.5.0.tar.bz2"
[ -f fixesproto-5.0.tar.bz2 ] || curl -sL -o fixesproto-5.0.tar.bz2 "$BASE_URL/proto/fixesproto-5.0.tar.bz2"
[ -f damageproto-1.2.1.tar.bz2 ] || curl -sL -o damageproto-1.2.1.tar.bz2 "$BASE_URL/proto/damageproto-1.2.1.tar.bz2"
[ -f xf86bigfontproto-1.2.0.tar.bz2 ] || curl -sL -o xf86bigfontproto-1.2.0.tar.bz2 "$BASE_URL/proto/xf86bigfontproto-1.2.0.tar.bz2"
[ -f fontsproto-2.1.3.tar.bz2 ] || curl -sL -o fontsproto-2.1.3.tar.bz2 "$BASE_URL/proto/fontsproto-2.1.3.tar.bz2"
[ -f videoproto-2.3.3.tar.bz2 ] || curl -sL -o videoproto-2.3.3.tar.bz2 "$BASE_URL/proto/videoproto-2.3.3.tar.bz2"
[ -f compositeproto-0.4.2.tar.bz2 ] || curl -sL -o compositeproto-0.4.2.tar.bz2 "$BASE_URL/proto/compositeproto-0.4.2.tar.bz2"
[ -f recordproto-1.14.2.tar.bz2 ] || curl -sL -o recordproto-1.14.2.tar.bz2 "$BASE_URL/proto/recordproto-1.14.2.tar.bz2"
[ -f resourceproto-1.2.0.tar.bz2 ] || curl -sL -o resourceproto-1.2.0.tar.bz2 "$BASE_URL/proto/resourceproto-1.2.0.tar.bz2"
[ -f scrnsaverproto-1.2.2.tar.bz2 ] || curl -sL -o scrnsaverproto-1.2.2.tar.bz2 "$BASE_URL/proto/scrnsaverproto-1.2.2.tar.bz2"
[ -f xcmiscproto-1.2.2.tar.bz2 ] || curl -sL -o xcmiscproto-1.2.2.tar.bz2 "$BASE_URL/proto/xcmiscproto-1.2.2.tar.bz2"
[ -f bigreqsproto-1.1.2.tar.bz2 ] || curl -sL -o bigreqsproto-1.1.2.tar.bz2 "$BASE_URL/proto/bigreqsproto-1.1.2.tar.bz2"
[ -f xtrans-1.4.0.tar.bz2 ] || curl -sL -o xtrans-1.4.0.tar.bz2 "$BASE_URL/lib/xtrans-1.4.0.tar.bz2"
[ -f xcb-proto-1.15.2.tar.xz ] || curl -sL -o xcb-proto-1.15.2.tar.xz "$BASE_URL/proto/xcb-proto-1.15.2.tar.xz"
[ -f libXau-1.0.9.tar.bz2 ] || curl -sL -o libXau-1.0.9.tar.bz2 "$BASE_URL/lib/libXau-1.0.9.tar.bz2"
[ -f libxcb-1.15.tar.xz ] || curl -sL -o libxcb-1.15.tar.xz "$BASE_URL/lib/libxcb-1.15.tar.xz"
[ -f libX11-1.8.4.tar.xz ] || curl -sL -o libX11-1.8.4.tar.xz "$BASE_URL/lib/libX11-1.8.4.tar.xz"
[ -f libxkbfile-1.1.2.tar.xz ] || curl -sL -o libxkbfile-1.1.2.tar.xz "$BASE_URL/lib/libxkbfile-1.1.2.tar.xz"
[ -f libfontenc-1.1.7.tar.xz ] || curl -sL -o libfontenc-1.1.7.tar.xz "$BASE_URL/lib/libfontenc-1.1.7.tar.xz"
[ -f libXfont-1.5.4.tar.bz2 ] || curl -sL -o libXfont-1.5.4.tar.bz2 "$BASE_URL/lib/libXfont-1.5.4.tar.bz2"
[ -f pixman-0.42.2.tar.gz ] || curl -sL -o pixman-0.42.2.tar.gz 'https://cairographics.org/releases/pixman-0.42.2.tar.gz'
[ -f freetype-2.13.2.tar.xz ] || curl -sL -o freetype-2.13.2.tar.xz 'https://download.savannah.gnu.org/releases/freetype/freetype-2.13.2.tar.xz'
[ -f zlib-1.3.1.tar.gz ] || curl -sL -o zlib-1.3.1.tar.gz 'https://zlib.net/zlib-1.3.1.tar.gz'
[ -f libressl-3.8.2.tar.gz ] || curl -sL -o libressl-3.8.2.tar.gz 'https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-3.8.2.tar.gz'
[ -f xorg-server-1.12.4.tar.gz ] || curl -sL -o xorg-server-1.12.4.tar.gz "$BASE_URL/xserver/xorg-server-1.12.4.tar.gz"
[ -f xkbcomp-1.4.7.tar.xz ] || curl -sL -o xkbcomp-1.4.7.tar.xz "$BASE_URL/app/xkbcomp-1.4.7.tar.xz"
[ -f xkeyboard-config-2.20.tar.bz2 ] || curl -sL -o xkeyboard-config-2.20.tar.bz2 "$BASE_URL/data/xkeyboard-config/xkeyboard-config-2.20.tar.bz2"
[ -f liberation-fonts-ttf-2.1.5.tar.gz ] || curl -sL -o liberation-fonts-ttf-2.1.5.tar.gz 'https://github.com/liberationfonts/liberation-fonts/files/7261482/liberation-fonts-ttf-2.1.5.tar.gz'

echo "=== Building protocols ==="
for pkg in xproto-7.0.31 xextproto-7.3.0 inputproto-2.3.2 kbproto-1.0.7 \
           renderproto-0.11.1 randrproto-1.5.0 fixesproto-5.0 damageproto-1.2.1 \
           xf86bigfontproto-1.2.0 fontsproto-2.1.3 videoproto-2.3.3 \
           compositeproto-0.4.2 recordproto-1.14.2 resourceproto-1.2.0 \
           scrnsaverproto-1.2.2 xcmiscproto-1.2.2 bigreqsproto-1.1.2; do
    [ -f "$INSTALL_DIR/lib/pkgconfig/${pkg%-*}.pc" ] && continue
    echo "  Building $pkg"
    rm -rf $pkg && for f in $pkg.tar.*; do tar xf "$f" 2>/dev/null && break; done
    cd $pkg && update_config
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR && make install
    cd .. && rm -rf $pkg
done

echo "=== Building xtrans ==="
[ -f "$INSTALL_DIR/share/pkgconfig/xtrans.pc" ] || {
    rm -rf xtrans-1.4.0 && tar xf xtrans-1.4.0.tar.bz2
    cd xtrans-1.4.0 && update_config
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR && make install
    cd .. && rm -rf xtrans-1.4.0
}

echo "=== Building xcb-proto ==="
[ -f "$INSTALL_DIR/share/pkgconfig/xcb-proto.pc" ] || {
    rm -rf xcb-proto-1.15.2 && tar xf xcb-proto-1.15.2.tar.xz
    cd xcb-proto-1.15.2 && update_config
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR && make install
    cd .. && rm -rf xcb-proto-1.15.2
}

echo "=== Building libXau ==="
[ -f "$INSTALL_DIR/lib/libXau.a" ] || {
    rm -rf libXau-1.0.9 && tar xf libXau-1.0.9.tar.bz2
    cd libXau-1.0.9 && update_config
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR --disable-shared --enable-static
    make -j$(nproc) && make install
    cd .. && rm -rf libXau-1.0.9
}

echo "=== Building libxcb ==="
[ -f "$INSTALL_DIR/lib/libxcb.a" ] || {
    rm -rf libxcb-1.15 && tar xf libxcb-1.15.tar.xz
    cd libxcb-1.15 && update_config
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR --disable-shared --enable-static
    make -j$(nproc) && make install
    cd .. && rm -rf libxcb-1.15
}

echo "=== Building libX11 ==="
[ -f "$INSTALL_DIR/lib/libX11.a" ] || {
    rm -rf libX11-1.8.4 && tar xf libX11-1.8.4.tar.xz
    cd libX11-1.8.4 && update_config
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR --disable-shared --enable-static \
        --disable-xf86bigfont --without-xmlto --disable-specs
    make -j$(nproc) && make install
    cd .. && rm -rf libX11-1.8.4
}

echo "=== Building libxkbfile ==="
[ -f "$INSTALL_DIR/lib/libxkbfile.a" ] || {
    rm -rf libxkbfile-1.1.2 && tar xf libxkbfile-1.1.2.tar.xz
    cd libxkbfile-1.1.2 && update_config
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR --disable-shared --enable-static
    make -j$(nproc) && make install
    cd .. && rm -rf libxkbfile-1.1.2
}

echo "=== Building zlib ==="
[ -f "$INSTALL_DIR/lib/libz.a" ] || {
    rm -rf zlib-1.3.1 && tar xf zlib-1.3.1.tar.gz
    cd zlib-1.3.1
    CHOST=i486-linux-musl ./configure --prefix=$INSTALL_DIR --static
    make -j$(nproc) && make install
    cd .. && rm -rf zlib-1.3.1
}

echo "=== Building libressl ==="
[ -f "$INSTALL_DIR/lib/libcrypto.a" ] || {
    rm -rf libressl-3.8.2 && tar xf libressl-3.8.2.tar.gz
    cd libressl-3.8.2
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR --disable-shared --enable-static --disable-hardening
    make -j$(nproc) && make install
    cd .. && rm -rf libressl-3.8.2
}

echo "=== Building freetype ==="
[ -f "$INSTALL_DIR/lib/pkgconfig/freetype2.pc" ] || {
    rm -rf freetype-2.13.2 && tar xf freetype-2.13.2.tar.xz
    cd freetype-2.13.2 && update_config
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR --disable-shared --enable-static \
        --without-png --without-harfbuzz --without-bzip2
    make -j$(nproc) && make install
    cd "$BUILD_DIR" && rm -rf freetype-2.13.2
}

echo "=== Building libfontenc ==="
[ -f "$INSTALL_DIR/lib/libfontenc.a" ] || {
    rm -rf libfontenc-1.1.7 && tar xf libfontenc-1.1.7.tar.xz
    cd libfontenc-1.1.7 && update_config
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR --disable-shared --enable-static
    make -j$(nproc) && make install
    cd "$BUILD_DIR" && rm -rf libfontenc-1.1.7
}

echo "=== Building libXfont ==="
[ -f "$INSTALL_DIR/lib/pkgconfig/xfont.pc" ] || {
    rm -rf libXfont-1.5.4 && tar xf libXfont-1.5.4.tar.bz2
    cd libXfont-1.5.4 && update_config
    FREETYPE_CFLAGS="-I$INSTALL_DIR/include/freetype2" \
    FREETYPE_LIBS="-L$INSTALL_DIR/lib -lfreetype -lz" \
    CFLAGS="-Os -fno-stack-protector -I$INSTALL_DIR/include -I$INSTALL_DIR/include/freetype2" \
    LDFLAGS="-static -L$INSTALL_DIR/lib" \
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR --disable-shared --enable-static
    make -j$(nproc) && make install
    cd "$BUILD_DIR" && rm -rf libXfont-1.5.4
}

echo "=== Building pixman ==="
[ -f "$INSTALL_DIR/lib/libpixman-1.a" ] || {
    rm -rf pixman-0.42.2 && tar xf pixman-0.42.2.tar.gz
    cd pixman-0.42.2 && update_config
    ./configure --host=i486-linux-musl --prefix=$INSTALL_DIR --disable-shared --enable-static
    make -j$(nproc) && make install
    cd "$BUILD_DIR" && rm -rf pixman-0.42.2
}

echo "=== Building Xfbdev ==="
rm -rf xorg-server-1.12.4 && tar xzf xorg-server-1.12.4.tar.gz
cd xorg-server-1.12.4 && update_config

# Apply patches (continue on failure, sed will fix it)
echo "  Applying patches..."
for patch in "$PATCHES_DIR"/xorg-server-1.12.4-*.patch; do
    [ -f "$patch" ] && patch -p1 < "$patch" || true
done

# Ensure fixes are applied (sed is idempotent)
sed -i 's/__uid_t/uid_t/g; s/__gid_t/gid_t/g' hw/kdrive/linux/linux.c
# Fix kinput.c device= option parsing bug (tam_key + 1 includes = in key name)
sed -i 's/strndup(string, tam_key + 1)/strndup(string, tam_key)/' hw/kdrive/src/kinput.c

FREETYPE_CFLAGS="-I$INSTALL_DIR/include/freetype2" \
FREETYPE_LIBS="-L$INSTALL_DIR/lib -lfreetype -lz" \
./configure --host=i486-linux-musl --prefix=/usr \
    --disable-xorg --disable-xnest --disable-xvfb \
    --enable-kdrive --enable-xfbdev \
    --enable-kdrive-kbd --enable-kdrive-mouse --enable-kdrive-evdev \
    --disable-xephyr --disable-dri --disable-dri2 --disable-glx --disable-xinerama \
    --disable-config-udev --disable-config-hal --disable-shared --enable-static --without-dtrace \
    --with-fontrootdir=/usr/share/fonts \
    --with-xkb-path=/usr/share/X11/xkb --with-xkb-output=/tmp \
    --with-xkb-bin-directory=/usr/bin \
    --with-default-xkb-rules=evdev --with-default-xkb-model=pc104 --with-default-xkb-layout=us \
    CFLAGS="-Os -fno-stack-protector -fno-pie -D_GNU_SOURCE -I$INSTALL_DIR/include -I$INSTALL_DIR/include/freetype2 -Wno-error" \
    LDFLAGS="-static -no-pie -L$INSTALL_DIR/lib -Wl,--allow-multiple-definition"

sed -i 's/^build_libtool_libs=yes/build_libtool_libs=no/; s/^link_all_deplibs=no/link_all_deplibs=yes/' libtool

# Build all (tests may fail but Xfbdev should still be built)
make -j$(nproc) || true
cd hw/kdrive/fbdev && make
i486-linux-musl-strip Xfbdev
cp Xfbdev $PKG_DIR/usr/bin/

# Include musl dynamic linker (Xfbdev needs it due to libtool)
MUSL_LIBC="$FLOPPINUX_DIR/i486-linux-musl-cross/i486-linux-musl/lib/libc.so"
mkdir -p $PKG_DIR/lib
cp "$MUSL_LIBC" $PKG_DIR/lib/
ln -sf libc.so $PKG_DIR/lib/ld-musl-i386.so.1
echo "Included musl libc.so for dynamic linking"

cd "$BUILD_DIR"
rm -rf xorg-server-1.12.4

echo "=== Building xkbcomp ==="
rm -rf xkbcomp-1.4.7 && tar xf xkbcomp-1.4.7.tar.xz
cd xkbcomp-1.4.7 && update_config
./configure --host=i486-linux-musl --prefix=/usr \
    CFLAGS="-Os -fno-pie -I$INSTALL_DIR/include" LDFLAGS="-static -no-pie -L$INSTALL_DIR/lib"
make -j$(nproc) LIBS="-lxkbfile -lX11 -lxcb -lXau"
i486-linux-musl-strip xkbcomp
cp xkbcomp $PKG_DIR/usr/bin/
cd "$BUILD_DIR"
rm -rf xkbcomp-1.4.7

echo "=== Installing xkeyboard-config ==="
rm -rf xkeyboard-config-2.20 && tar xf xkeyboard-config-2.20.tar.bz2
cd xkeyboard-config-2.20
./configure --prefix=/usr --disable-runtime-deps
make -C rules
cp -r rules symbols types compat keycodes geometry $PKG_DIR/usr/share/X11/xkb/
echo 'default xkb_compatibility "default" { include "basic" };' > $PKG_DIR/usr/share/X11/xkb/compat/default
echo 'default xkb_types "default" { include "basic" };' > $PKG_DIR/usr/share/X11/xkb/types/default
echo 'default xkb_symbols "default" { include "us(basic)" };' > $PKG_DIR/usr/share/X11/xkb/symbols/default
cd "$BUILD_DIR"
rm -rf xkeyboard-config-2.20

echo "=== Adding fonts ==="
tar xf liberation-fonts-ttf-2.1.5.tar.gz
cp liberation-fonts-ttf-2.1.5/*.ttf $PKG_DIR/usr/share/fonts/TTF/
rm -rf liberation-fonts-ttf-2.1.5

echo "=== Creating startx script ==="
cat > $PKG_DIR/usr/bin/startx << 'EOF'
#!/bin/sh
# startx - Start X server with window manager
export XKB_CONFIG_ROOT=/usr/share/X11/xkb
export DISPLAY=:0

# Find keyboard device
KBD_DEV=""
for ev in /dev/input/event*; do
    [ -e "$ev" ] || continue
    name=$(cat /sys/class/input/$(basename $ev)/device/name 2>/dev/null)
    case "$name" in
        *[Kk]eyboard*|*AT*|*translated*)
            KBD_DEV="$ev"
            break
            ;;
    esac
done

if [ -n "$KBD_DEV" ]; then
    KBD_OPT="-keybd evdev,,device=$KBD_DEV"
else
    KBD_OPT="-keybd keyboard"
fi

echo "Starting X with keyboard: $KBD_OPT"
Xfbdev :0 -ac $KBD_OPT -mouse mouse,/dev/input/mice &
XPID=$!
sleep 2

# Run window manager
${1:-dwm}

# Cleanup
kill $XPID 2>/dev/null
EOF
chmod +x $PKG_DIR/usr/bin/startx

echo "=== Creating package ==="
cd $PKG_DIR && tar czf "$REPO_DIR/xfbdev-full.pkg.tar.gz" .
cd "$BUILD_DIR"
rm -rf $PKG_DIR

echo ""
echo "========================================"
echo "Build complete: xfbdev-full.pkg.tar.gz"
echo "Size: $(du -h "$REPO_DIR/xfbdev-full.pkg.tar.gz" | cut -f1)"
echo "========================================"
echo ""
echo "Kernel requirements:"
echo "  CONFIG_MULTIUSER=y"
echo "  CONFIG_INPUT_MOUSEDEV=y"
echo "  CONFIG_INPUT_EVDEV=y"
echo "  CONFIG_FB=y"
echo "  CONFIG_FB_VESA=y"
echo ""
echo "Patches applied from: $PATCHES_DIR"
ls -la "$PATCHES_DIR"/xorg-server-*.patch 2>/dev/null || true
