#!/bin/bash
# run-qemu.sh [DIR] - Boot Ginebra like on the real hardware: Pentium III, 32MB RAM, ONE floppy drive.
# DIR defaults to out/ (needs floppy1-boot.img and floppy2-rootfs.img).
#
# When the kernel shows "Press <ENTER> to see video modes..." (vga=ask), swap the disk.
# This script does it for you: it types the swap command in the QEMU monitor, then you press SPACE.
# NIC=ne2k_pci uses the NE2000 card instead of the RTL8139 (QEMU emulates an RTL8139C+,
# which 8139too rejects; real RTL8139/A/B/C/D cards work with 8139too).
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$(realpath "${1:-$ROOT/out}")"
NIC=${NIC:-rtl8139}
QEMU=$(command -v qemu-system-i386 || command -v qemu-system-x86_64)
echo "Booting disk 1. At the 'Press <ENTER>' prompt the disk will be swapped to disk 2 (write-protected)."
echo "Then press SPACE in the QEMU window."
(
  sleep "${SWAP_AFTER:-8}"
  echo "change floppy0 $DIR/floppy2-rootfs.img raw read-only"
  cat
) | "$QEMU" -machine pc -cpu pentium3 -m "${MEM:-32}" \
      -drive file="$DIR/floppy1-boot.img",format=raw,if=floppy,index=0,readonly=on -boot a \
      -netdev user,id=n0 -device "$NIC",netdev=n0 \
      -monitor stdio $QEMU_OPTS
