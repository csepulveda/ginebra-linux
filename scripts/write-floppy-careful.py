#!/usr/bin/env python3
"""write-floppy-careful.py IMAGE DEVICE - Write a floppy track by track, verifying as it goes.

For worn (USB) floppy drives that lose head alignment: after writing each track it reads the
track back and re-reads sector 0 (a known sector) to check the head is still where it should be.
A track that doesn't match is rewritten. A final pass verifies the whole disk again, because a
misplaced write can overwrite a track that was already verified.
Use scripts/write-floppy.sh for the device safety checks; this script assumes DEVICE is a floppy.
"""
import mmap, os, sys, time

SEC, SPT, TOTAL = 512, 18, 2880
TRACK = SEC * SPT
RETRIES = int(os.environ.get('RETRIES', 5))
img_path, dev = sys.argv[1], sys.argv[2]
img = open(img_path, 'rb').read()
assert len(img) == SEC * TOTAL, 'image must be 1474560 bytes'

fd = os.open(dev, os.O_RDWR | os.O_DIRECT | os.O_SYNC)
buf = mmap.mmap(-1, TRACK)  # page-aligned, required by O_DIRECT


def write_track(t):
    buf[:] = img[t * SEC:t * SEC + TRACK]
    try:
        return os.pwritev(fd, [buf], t * SEC) == TRACK
    except OSError:
        return False


def read(lba, n):
    try:
        if os.preadv(fd, [memoryview(buf)[:n * SEC]], lba * SEC) != n * SEC:
            return None
        return bytes(buf[:n * SEC])
    except OSError:
        return None


def track_ok(t):
    return read(t, SPT) == img[t * SEC:t * SEC + TRACK]


def head_ok():
    return read(0, 1) == img[:SEC]


def write_verified(t):
    for attempt in range(1, RETRIES + 1):
        if write_track(t) and track_ok(t) and head_ok():
            return attempt
        time.sleep(1)
    return 0


t0 = time.time()
failed = []
for t in range(0, TOTAL, SPT):
    n = write_verified(t)
    if not n:
        failed.append(t // SPT)
    status = 'ok' if n == 1 else (f'ok after {n} tries' if n else 'FAILED')
    print(f'[{time.time() - t0:4.0f}s] track {t // SPT:3d} {status}', flush=True)

for p in range(1, 4):
    bad = [t for t in range(0, TOTAL, SPT) if not track_ok(t)]
    print(f'final verify pass {p}: {len(bad)} bad tracks {[t // SPT for t in bad]}', flush=True)
    if not bad:
        print('OK: disk matches image.')
        sys.exit(0)
    for t in bad:
        write_verified(t)
print('FAILED: disk does not match image. Try cleaning the drive head or another drive/floppy.')
sys.exit(2)
