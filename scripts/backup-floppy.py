#!/usr/bin/env python3
"""backup-floppy.py DEVICE IMAGE - Resumable, read-only backup of a (possibly failing) floppy.

- Never writes to DEVICE. Reads with O_DIRECT so one bad sector doesn't poison a 4 KB page.
- Reads track by track; tracks with errors are retried sector by sector at the end (PASSES=n).
- Detects head miscalibration (common in worn USB drives): after every track it re-reads
  sector 0 and compares it with the first read. If it changes, the drive is reading the
  wrong cylinder; the track is discarded and the backup stops. Replug the drive and rerun:
  progress is kept in IMAGE.map ('?' unread, '+' ok, '-' error).
"""
import mmap, os, sys, time
dev, img = sys.argv[1], sys.argv[2]; mp = img + '.map'
SEC, SPT, TOTAL = 512, 18, 2880
PASSES = int(os.environ.get('PASSES', 2))
if not os.path.exists(img): open(img, 'wb').write(b'\0' * SEC * TOTAL)
m = list(open(mp).read()) if os.path.exists(mp) else ['?'] * TOTAL
fd = os.open(dev, os.O_RDONLY | os.O_DIRECT); out = os.open(img, os.O_WRONLY)
buf = mmap.mmap(-1, SEC * SPT)  # page-aligned, required by O_DIRECT

def read(lba, n):
    try: return os.preadv(fd, [memoryview(buf)[:n * SEC]], lba * SEC) == n * SEC
    except OSError: return False
def save():
    open(mp + '.tmp', 'w').write(''.join(m)); os.replace(mp + '.tmp', mp)
def stat(): return f"ok={m.count('+')} bad={m.count('-')} unread={m.count('?')}"

if not (read(0, 1) and (s0 := bytes(buf[:SEC])) and read(0, 1) and bytes(buf[:SEC]) == s0):
    sys.exit("Cannot read sector 0 consistently: wrong disk, empty drive or misaligned head.")
def head_ok(): return read(0, 1) and bytes(buf[:SEC]) == s0

t0 = time.time()
for t in range(0, TOTAL, SPT):
    if '?' not in m[t:t + SPT]: continue
    ok = read(t, SPT); data = bytes(buf[:SPT * SEC])
    if not head_ok():
        save(); sys.exit(f"Head miscalibration detected at track {t // SPT}. Replug the drive and rerun. {stat()}")
    if ok: os.pwrite(out, data, t * SEC); m[t:t + SPT] = ['+'] * SPT
    else: m[t:t + SPT] = ['+' if c == '+' else '-' for c in m[t:t + SPT]]
    save(); print(f"[{time.time() - t0:4.0f}s] track {t // SPT:3d} {'ok ' if ok else 'ERR'} {stat()}", flush=True)
for p in range(PASSES):
    for s in [i for i, c in enumerate(m) if c == '-']:
        ok = read(s, 1); data = bytes(buf[:SEC])
        if not head_ok():
            save(); sys.exit(f"Head miscalibration detected. Replug the drive and rerun. {stat()}")
        if ok: os.pwrite(out, data, s * SEC); m[s] = '+'
        save()
    print(f"retry pass {p + 1}: {stat()}", flush=True)
print("DONE", stat())
