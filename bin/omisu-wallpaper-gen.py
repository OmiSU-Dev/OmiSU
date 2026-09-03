#!/usr/bin/env python3
# omisu:summary=Generate OmiSu desktop wallpapers from flat theme palettes.
#
# omisu-wallpaper-gen — generate original OmiSu desktop wallpapers.
#
# Pure-python PNG writer (no PIL needed): a diagonal gradient from the theme
# BG toward a darker shade, with a soft accent-colored radial glow. Produces
# theme-matched wallpapers for omisu-theme to pick from.
#
import math
import struct
import sys
import zlib


def write_png(path, w, h, rows):
    def chunk(t, d):
        c = t + d
        return struct.pack(">I", len(d)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)

    raw = bytearray()
    for row in rows:
        raw.append(0)
        for (r, g, b) in row:
            raw += bytes((r & 255, g & 255, b & 255))
    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)
    idat = zlib.compress(bytes(raw), 9)
    with open(path, "wb") as f:
        f.write(sig + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b""))


def hex_rgb(h):
    h = h.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def gen(bg_hex, accent_hex, path, w=1600, h=900, ember_hex=None):
    br, bg, bb = hex_rgb(bg_hex)
    ar, ag, ab = hex_rgb(accent_hex)
    cx, cy = w * 0.5, h * 0.40
    maxd = math.hypot(w, h)
    emb = hex_rgb(ember_hex) if ember_hex else None
    rows = []
    for y in range(h):
        row = []
        for x in range(w):
            t = x / w * 0.5 + y / h * 0.5
            r = br * (1 - 0.28 * t)
            g = bg * (1 - 0.28 * t)
            b = bb * (1 - 0.28 * t)
            d = math.hypot(x - cx, y - cy) / maxd
            glow = max(0.0, 1 - d * 1.7)
            glow = glow * glow * 0.38
            r = r * (1 - glow) + ar * glow
            g = g * (1 - glow) + ag * glow
            b = b * (1 - glow) + ab * glow
            if emb is not None:
                er, eg, eb = emb
                d2 = math.hypot(x - w * 0.5, y - h * 0.72) / maxd
                glow2 = max(0.0, 1 - d2 * 1.9)
                glow2 = glow2 * glow2 * 0.30
                r = r * (1 - glow2) + er * glow2
                g = g * (1 - glow2) + eg * glow2
                b = b * (1 - glow2) + eb * glow2
            row.append((int(r), int(g), int(b)))
        rows.append(row)
    write_png(path, w, h, rows)


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    gen("1e1e2e", "89b4fa", f"{out}/catppuccin.png")
    gen("1a1b26", "7aa2f7", f"{out}/tokyonight.png")
    # Phoenix: deep violet base, gold crown glow, orange ember below.
    gen("241734", "ffce5c", f"{out}/phoenix.png", ember_hex="ff7a18")
    print("wrote catppuccin.png + tokyonight.png + phoenix.png")
