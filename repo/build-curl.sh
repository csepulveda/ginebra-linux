#!/bin/bash
# build-curl.sh - Generates curl.pkg.tar.gz (with HTTPS support via mbedTLS)

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

INSTALL_DIR="$BUILD_DIR/curl-deps"
mkdir -p "$INSTALL_DIR"

# ============================================
# 1. Build mbedTLS (lightweight SSL library)
# ============================================
echo "[1/3] Building mbedTLS..."
[ -f mbedtls-3.6.5.tar.bz2 ] || wget https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-3.6.5/mbedtls-3.6.5.tar.bz2
rm -rf mbedtls-3.6.5
tar xjf mbedtls-3.6.5.tar.bz2
cd mbedtls-3.6.5

make -j$(nproc) -C library \
    CC=i486-linux-musl-gcc \
    AR=i486-linux-musl-ar \
    CFLAGS="-Os"

mkdir -p "$INSTALL_DIR/include" "$INSTALL_DIR/lib"
cp -r include/mbedtls "$INSTALL_DIR/include/"
cp -r include/psa "$INSTALL_DIR/include/"
cp library/*.a "$INSTALL_DIR/lib/"
cd "$BUILD_DIR"

# ============================================
# 2. Download CA certificates
# ============================================
echo "[2/3] Downloading CA certificates..."
[ -f ca-certificates.crt ] || wget https://curl.se/ca/cacert.pem -O ca-certificates.crt

# ============================================
# 3. Build curl with mbedTLS
# ============================================
echo "[3/3] Building curl..."
[ -f curl-8.11.1.tar.gz ] || wget https://curl.se/download/curl-8.11.1.tar.gz
rm -rf curl-8.11.1
tar xzf curl-8.11.1.tar.gz
cd curl-8.11.1

export CFLAGS="-Os -I$INSTALL_DIR/include"
export LDFLAGS="-static -L$INSTALL_DIR/lib"
export LIBS="-lmbedtls -lmbedx509 -lmbedcrypto"
export PKG_CONFIG=/bin/false

./configure \
    --host=i486-linux-musl \
    --disable-shared --enable-static \
    --with-mbedtls="$INSTALL_DIR" \
    --with-ca-bundle=/etc/ssl/certs/ca-certificates.crt \
    --disable-debug --disable-curldebug --disable-dependency-tracking \
    --disable-docs --disable-manual \
    --without-libssh2 --without-librtmp --without-libidn2 \
    --without-nghttp2 --without-zstd --without-brotli --without-zlib --without-libpsl \
    --disable-ldap --disable-ldaps --disable-rtsp --disable-dict \
    --disable-telnet --disable-tftp --disable-pop3 --disable-imap \
    --disable-smb --disable-smtp --disable-gopher --disable-mqtt \
    --enable-http --enable-https --enable-ftp

sed -i 's/^link_all_deplibs=no/link_all_deplibs=yes/' libtool
sed -i 's/^build_libtool_libs=yes/build_libtool_libs=no/' libtool

make -j$(nproc) LDFLAGS="-all-static -L$INSTALL_DIR/lib"
i486-linux-musl-strip src/curl

# Create package
mkdir -p "$BUILD_DIR/pkg/usr/bin" "$BUILD_DIR/pkg/etc/ssl/certs"
cp src/curl "$BUILD_DIR/pkg/usr/bin/"
cp "$BUILD_DIR/ca-certificates.crt" "$BUILD_DIR/pkg/etc/ssl/certs/"
chmod +x "$BUILD_DIR/pkg/usr/bin/curl"
cd "$BUILD_DIR/pkg"
tar czf "$REPO_DIR/curl.pkg.tar.gz" .

# Cleanup
rm -rf "$BUILD_DIR/pkg" "$BUILD_DIR/mbedtls-3.6.5" "$BUILD_DIR/curl-8.11.1" "$BUILD_DIR/curl-deps"

echo ""
echo "Created: $REPO_DIR/curl.pkg.tar.gz ($(du -h "$REPO_DIR/curl.pkg.tar.gz" | cut -f1))"
