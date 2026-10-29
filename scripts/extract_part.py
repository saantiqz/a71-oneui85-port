#!/usr/bin/env python3
# Stream a SPARSE super image on stdin and extract ONE logical partition (no temp files).
import sys, struct
PART, OUT = sys.argv[1], sys.argv[2]
inp = sys.stdin.buffer
def rd(n):
    b = bytearray()
    while len(b) < n:
        c = inp.read(n - len(b))
        if not c: sys.exit("unexpected end of input")
        b += c
    return bytes(b)
magic, _, _, fhs, chs, blk, tblk, tch, _ = struct.unpack('<IHHHHIIII', rd(28))
if magic != 0xED26FF3A: sys.exit("input is not a sparse image")
if fhs > 28: rd(fhs - 28)
HEAD = 1 << 20; head = bytearray(); ext = None; out = None; pos = 0
def parse(h):
    g = 4096
    if struct.unpack_from('<I', h, g)[0] != 0x616C4467: sys.exit("no LP geometry found")
    m = 4096 + 2 * 4096
    if struct.unpack_from('<I', h, m)[0] != 0x414C5030: sys.exit("no LP metadata found")
    hsize = struct.unpack_from('<I', h, m + 8)[0]
    po, pn, pe = struct.unpack_from('<III', h, m + 80)
    eo, en, ee = struct.unpack_from('<III', h, m + 92)
    t = m + hsize
    for i in range(pn):
        b = t + po + i * pe
        name = h[b:b+36].split(b'\0')[0].decode()
        fe, ne = struct.unpack_from('<II', h, b + 40)
        if name == PART:
            res, o = [], 0
            for j in range(fe, fe + ne):
                ns, tt, td = struct.unpack_from('<QIQ', h, t + eo + j * ee)
                if tt == 0: res.append((td * 512, td * 512 + ns * 512, o))
                o += ns * 512
            return res, o
    sys.exit(f"partition '{PART}' not found")
def emit(s, data):
    global ext, out
    if ext is None:
        if s < HEAD: head.extend(data[:HEAD - s] if s + len(data) > HEAD else data)
        if len(head) >= HEAD or s + len(data) >= HEAD:
            ext, size = parse(bytes(head)); out = open(OUT, 'wb'); out.truncate(size)
            print(f"{PART}: {size/1e6:.0f} MB in {len(ext)} extent(s)", file=sys.stderr)
        else: return
    e = s + len(data)
    for a, b, o in ext:
        lo, hi = max(a, s), min(b, e)
        if lo < hi: out.seek(o + lo - a); out.write(data[lo - s:hi - s])
for c in range(tch):
    ctype, _, csz, tsz = struct.unpack('<HHII', rd(chs))
    n = csz * blk
    if ctype == 0xCAC1:
        left = n
        while left:
            k = min(left, 8 << 20); emit(pos, rd(k)); pos += k; left -= k
    elif ctype == 0xCAC2:
        pat = rd(4)
        for off in range(0, n, 8 << 20):
            k = min(8 << 20, n - off); emit(pos, pat * (k // 4)); pos += k
    elif ctype == 0xCAC3: pos += n
    elif ctype == 0xCAC4: rd(4)
    else: sys.exit(f"unknown chunk type {ctype:#x}")
    if c % 200 == 0: print(f"\r  {100*c//tch}%", end='', file=sys.stderr, flush=True)
print("\r  100%", file=sys.stderr)
if out: out.close()
else: sys.exit("metadata never found")
