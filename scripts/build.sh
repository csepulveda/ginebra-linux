#!/bin/bash
# build.sh - Build kernel, modules and both floppy images inside an Ubuntu 24.04 container.
# Usage: scripts/build.sh [kernel|busybox|floppies|all]   (default: all = kernel + floppies)
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENGINE=${ENGINE:-$(command -v podman || command -v docker)}
IMAGE=ginebra-build
"$ENGINE" build -q -t "$IMAGE" -f "$ROOT/scripts/Containerfile" "$ROOT/scripts" >/dev/null
run() { "$ENGINE" run --rm -v "$ROOT:/ginebra:Z" -w /ginebra "$IMAGE" "$@"; }
case "${1:-all}" in
    kernel)   run scripts/build-kernel.sh ;;
    busybox)  run scripts/build-busybox.sh ;;
    floppies) run scripts/make-floppies.sh ;;
    all)      run scripts/build-kernel.sh && run scripts/make-floppies.sh ;;
    *) echo "usage: $0 [kernel|busybox|floppies|all]"; exit 1 ;;
esac
