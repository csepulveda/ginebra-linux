#!/bin/bash
# build-busybox.sh - Build BusyBox 1.36.1 (static, musl, i486) from config/busybox-1.36.1.config
# Run inside the build container (see scripts/build.sh). Result: out/busybox
# The config reproduces filesystem/bin/busybox (485,000 bytes, 73 applets); only the build date differs.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VER=1.36.1; DL="$ROOT/dl"; OUT="$ROOT/out"; mkdir -p "$DL" "$OUT"

"$ROOT/scripts/get-toolchain.sh"
export PATH="$ROOT/i486-linux-musl-cross/bin:$PATH"

[ -f "$DL/busybox-$VER.tar.bz2" ] || wget -q -O "$DL/busybox-$VER.tar.bz2" \
    "https://busybox.net/downloads/busybox-$VER.tar.bz2"
mkdir -p "$ROOT/busybox-1_36_1"
find "$ROOT/busybox-1_36_1" -mindepth 1 -maxdepth 1 ! -name .gitignore -exec rm -rf {} +
tar --no-same-owner -xjf "$DL/busybox-$VER.tar.bz2" -C "$ROOT/busybox-1_36_1" --strip-components=1

cd "$ROOT/busybox-1_36_1"
cp "$ROOT/config/busybox-$VER.config" .config
make oldconfig </dev/null >/dev/null
make -j"$(nproc)"
cp busybox "$OUT/busybox"
echo "busybox: $(stat -c %s "$OUT/busybox") bytes (shipped: $(stat -c %s "$ROOT/filesystem/bin/busybox"))"
echo "To use it: cp out/busybox filesystem/bin/busybox"
