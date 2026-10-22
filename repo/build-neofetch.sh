#!/bin/bash
# build-neofetch.sh - Generates neofetch.pkg.tar.gz (shell script from repo/src, no compiling)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$SCRIPT_DIR"
BUILD_DIR="$REPO_DIR/build"

rm -rf "$BUILD_DIR/pkg"
mkdir -p "$BUILD_DIR/pkg/usr/bin"
cp "$REPO_DIR/src/neofetch" "$BUILD_DIR/pkg/usr/bin/"
chmod +x "$BUILD_DIR/pkg/usr/bin/neofetch"
cd "$BUILD_DIR/pkg"
tar czf "$REPO_DIR/neofetch.pkg.tar.gz" .

rm -rf "$BUILD_DIR/pkg"

echo ""
echo "Created: $REPO_DIR/neofetch.pkg.tar.gz ($(du -h "$REPO_DIR/neofetch.pkg.tar.gz" | cut -f1))"
