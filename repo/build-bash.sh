#!/bin/bash
# build-bash.sh - Generates bash.pkg.tar.gz

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
BUILD_DIR="$REPO_DIR/build"
TOOLCHAIN="/home/cesar/floppinux/i486-linux-musl-cross"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

[ -f bash-5.2.tar.gz ] || wget https://ftp.gnu.org/gnu/bash/bash-5.2.tar.gz
rm -rf bash-5.2
tar xzf bash-5.2.tar.gz
cd bash-5.2

export PATH="$TOOLCHAIN/bin:$PATH"
export CC=i486-linux-musl-gcc
export AR=i486-linux-musl-ar
export RANLIB=i486-linux-musl-ranlib
export CFLAGS="-Os"
export LDFLAGS="-static"

cat > config.cache << 'CACHE'
bash_cv_func_strtoimax=yes
bash_cv_func_strtoumax=yes
ac_cv_func_strtoimax=yes
ac_cv_func_strtoumax=yes
bash_cv_must_reinstall_sighandlers=no
bash_cv_func_sigsetjmp=present
bash_cv_func_strcoll_broken=no
bash_cv_func_ctype_nonascii=no
bash_cv_dup2_broken=no
bash_cv_getenv_redef=yes
bash_cv_sys_siglist=yes
bash_cv_wcwidth_broken=no
CACHE

./configure \
    --host=i486-linux-musl \
    --cache-file=config.cache \
    --enable-static-link \
    --without-bash-malloc \
    --disable-nls \
    --disable-bang-history \
    --disable-progcomp \
    --disable-net-redirections

make -j$(nproc) || true
i486-linux-musl-ar d lib/sh/libsh.a strtoimax.o 2>/dev/null || true
i486-linux-musl-ar d lib/sh/libsh.a strtoumax.o 2>/dev/null || true

make
i486-linux-musl-strip bash

# Create package
mkdir -p "$BUILD_DIR/pkg/usr/bin"
cp bash "$BUILD_DIR/pkg/usr/bin/"
chmod +x "$BUILD_DIR/pkg/usr/bin/bash"
cd "$BUILD_DIR/pkg"
tar czf "$REPO_DIR/bash.pkg.tar.gz" .

# Cleanup
rm -rf "$BUILD_DIR/pkg" "$BUILD_DIR/bash-5.2"

echo ""
echo "Created: $REPO_DIR/bash.pkg.tar.gz ($(du -h "$REPO_DIR/bash.pkg.tar.gz" | cut -f1))"
