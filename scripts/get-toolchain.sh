#!/bin/bash
# get-toolchain.sh - Download the i486 musl cross toolchain (musl.cc) into i486-linux-musl-cross/
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; DL="$ROOT/dl"; mkdir -p "$DL"
[ -x "$ROOT/i486-linux-musl-cross/bin/i486-linux-musl-gcc" ] && exit 0
[ -f "$DL/i486-linux-musl-cross.tgz" ] || wget -q -O "$DL/i486-linux-musl-cross.tgz" \
    https://musl.cc/i486-linux-musl-cross.tgz
tar --no-same-owner -xzf "$DL/i486-linux-musl-cross.tgz" -C "$ROOT"
