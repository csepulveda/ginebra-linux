#!/bin/bash
# build-kernel.sh - Build bzImage + modules from config/kernel-$KVER.config
# Run inside the build container (see scripts/build.sh).
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KVER=6.14.11
DL="$ROOT/dl"; mkdir -p "$DL"

if [ ! -f "$ROOT/linux/Makefile" ]; then
    [ -f "$DL/linux-$KVER.tar.xz" ] || wget -q -O "$DL/linux-$KVER.tar.xz" \
        "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KVER.tar.xz"
    tar --no-same-owner -xf "$DL/linux-$KVER.tar.xz" -C "$ROOT"
    rm -rf "$ROOT/linux"; mv "$ROOT/linux-$KVER" "$ROOT/linux"
fi

cd "$ROOT/linux"
cp "$ROOT/config/kernel-$KVER.config" .config
make ARCH=x86 olddefconfig
make ARCH=x86 bzImage -j"$(nproc)"
find . -name "*.ko" -delete
make ARCH=x86 modules -j"$(nproc)"

echo "bzImage: $(stat -c %s arch/x86/boot/bzImage) bytes"
find . -name "*.ko" -printf "  %f %s\n" | sort
