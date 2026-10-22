#!/bin/bash
# write-floppy.sh IMAGE DEVICE - Write a floppy image and verify it by reading it back.
# Refuses to touch anything that is not a 1.44MB removable disk.
# Example: sudo scripts/write-floppy.sh out/floppy1-boot.img /dev/sda
set -e
IMG=$1; DEV=$2
[ -f "$IMG" ] && [ -b "$DEV" ] || { echo "usage: $0 IMAGE DEVICE"; exit 1; }
SIZE=$(blockdev --getsize64 "$DEV")
NAME=$(basename "$(readlink -f "$DEV")")
[ "$SIZE" = 1474560 ] || { echo "$DEV is $SIZE bytes, not a 1.44MB floppy. Aborting."; exit 1; }
[ "$(cat /sys/block/$NAME/removable 2>/dev/null)" = 1 ] || [ "${NAME#fd}" != "$NAME" ] || { echo "$DEV is not removable. Aborting."; exit 1; }
[ "$(stat -c %s "$IMG")" = 1474560 ] || { echo "$IMG is not a 1.44MB image. Aborting."; exit 1; }
grep -q "^$DEV" /proc/mounts && { echo "$DEV is mounted. Unmount it first."; exit 1; }

echo "Writing $IMG -> $DEV track by track, verifying each one ..."
blockdev --setrw "$DEV"
if python3 "$(dirname "$0")/write-floppy-careful.py" "$IMG" "$DEV"; then
    echo "Now slide the write-protect tab to the OPEN (protected) position."
else
    echo "VERIFY FAILED: this floppy is unreliable, use another one."; exit 2
fi
