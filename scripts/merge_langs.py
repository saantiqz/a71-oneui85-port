#!/usr/bin/env python3
# Copy translations for languages our Settings lacks, keeping only texts our Settings uses.
# v1.0.1: translations taken from the S23 FE global (SM-S711B, EUX, Android 16) SecSettings.
# Usage: merge_langs.py <our_res_dir> <donor_res_dir>   (both decoded with apktool)
import os, re, sys
OURS, THEIRS = sys.argv[1], sys.argv[2]
LOC = re.compile(r'^values-([a-z]{2,3}(-r[A-Z]{2})?|b\+[A-Za-z0-9+]+)$')
ELEM = {'strings.xml': re.compile(r'<string name="([^"]+)"[^>]*?(?:/>|>.*?</string>)', re.S),
        'plurals.xml': re.compile(r'<plurals name="([^"]+)"[^>]*>.*?</plurals>', re.S)}
known = {}
for fn, rx in ELEM.items():
    p = os.path.join(OURS, 'values', fn)
    known[fn] = set(rx.findall(open(p, encoding='utf-8').read())) if os.path.exists(p) else set()
    print(f"our default {fn}: {len(known[fn])} entries")
added = 0
for d in sorted(os.listdir(THEIRS)):
    if not LOC.match(d) or os.path.exists(os.path.join(OURS, d)): continue
    os.makedirs(os.path.join(OURS, d))
    kept = 0
    for fn, rx in ELEM.items():
        src = os.path.join(THEIRS, d, fn)
        if not os.path.exists(src): continue
        items = [m.group(0) for m in rx.finditer(open(src, encoding='utf-8').read()) if m.group(1) in known[fn]]
        if items:
            with open(os.path.join(OURS, d, fn), 'w', encoding='utf-8') as f:
                f.write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    ' + '\n    '.join(items) + '\n</resources>\n')
            kept += len(items)
    if kept: added += 1; print(f"  + {d}: {kept} texts")
    else: os.rmdir(os.path.join(OURS, d))
print(f"done: {added} languages added")
