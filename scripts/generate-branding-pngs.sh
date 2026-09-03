#!/usr/bin/env bash
# Generate OmiSu Plymouth + SDDM PNG assets (stdlib Python; no ImageMagick required).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLYMOUTH="$ROOT/default/plymouth"
SDDM="$ROOT/default/sddm/omisu"
mkdir -p "$PLYMOUTH" "$SDDM"

python3 - "$PLYMOUTH" "$SDDM" <<'PY'
import os, struct, sys, zlib, math, shutil

plymouth, sddm = sys.argv[1:3]

def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(
        ">I", zlib.crc32(tag + data) & 0xFFFFFFFF
    )

def write_png(path, w, h, rgba_fn):
    rows = []
    for y in range(h):
        row = b"\x00"
        for x in range(w):
            row += bytes(rgba_fn(x, y))
        rows.append(row)
    raw = b"".join(rows)
    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )
    with open(path, "wb") as fh:
        fh.write(png)

def circle(cx, cy, r):
    def fn(x, y):
        d = math.hypot(x - cx, y - cy)
        if d <= r:
            a = 255 if d <= r - 0.5 else int(255 * (r - d))
            return (255, 255, 255, a)
        return (0, 0, 0, 0)
    return fn

def rect(x0, y0, x1, y1, radius=0):
    def fn(x, y):
        if x < x0 or x > x1 or y < y0 or y > y1:
            return (0, 0, 0, 0)
        if radius:
            corners = (
                (x0 + radius, y0 + radius),
                (x1 - radius, y0 + radius),
                (x0 + radius, y1 - radius),
                (x1 - radius, y1 - radius),
            )
            for cx, cy in corners:
                if (x < x0 + radius or x > x1 - radius) and (y < y0 + radius or y > y1 - radius):
                    if math.hypot(x - cx, y - cy) > radius:
                        return (0, 0, 0, 0)
        return (255, 255, 255, 255)
    return fn

def entry_box(x0, y0, x1, y1, radius, fill, border, border_w=2):
    """Dark rounded box with a light border — the OmiSu-style password
    entry. A solid white rect made the field invisible: white bullets were
    painted onto a white box."""
    def inside(x, y, ix0, iy0, ix1, iy1, r):
        if x < ix0 or x > ix1 or y < iy0 or y > iy1:
            return False
        if r > 0:
            for cx, cy in (
                (ix0 + r, iy0 + r), (ix1 - r, iy0 + r),
                (ix0 + r, iy1 - r), (ix1 - r, iy1 - r),
            ):
                if (x < ix0 + r or x > ix1 - r) and (y < iy0 + r or y > iy1 - r):
                    if math.hypot(x - cx, y - cy) > r:
                        return False
        return True
    def fn(x, y):
        if not inside(x, y, x0, y0, x1, y1, radius):
            return (0, 0, 0, 0)
        if inside(x, y, x0 + border_w, y0 + border_w, x1 - border_w, y1 - border_w,
                  max(0, radius - border_w)):
            return (*fill, 235)
        return (*border, 255)
    return fn

def wave_band(w, h, amplitude, period, thickness=3, alpha=200):
    def fn(x, y):
        mid = (h - 1) / 2.0
        wave_y = mid + amplitude * math.sin(2 * math.pi * x / period)
        dist = abs(y - wave_y)
        if dist <= thickness:
            a = int(alpha * max(0.0, 1.0 - dist / thickness))
            return (255, 255, 255, a)
        return (0, 0, 0, 0)
    return fn

def tint(src, color):
    r, g, b = color
    def fn(x, y):
        pr, pg, pb, pa = src(x, y)
        if pa == 0:
            return (0, 0, 0, 0)
        return (r, g, b, pa)
    return fn

GLYPHS = {
    "O": (" 111 ", "1   1", "1   1", "1   1", " 111 "),
    "M": ("1   1", "11 11", "1 1 1", "1   1", "1   1"),
    "I": (" 111 ", "  1  ", "  1  ", "  1  ", " 111 "),
    "S": (" 111 ", "1    ", " 111 ", "    1", " 111 "),
    "U": ("1   1", "1   1", "1   1", "1   1", " 111 "),
    " ": ("     ", "     ", "     ", "     ", "     "),
}

# お任せ pre-rasterized from a CJK system font (scripts/render-omakase-bitmap.py);
# embedded so this generator stays stdlib-only on build hosts with no CJK fonts.
OMAKASE_BITMAP = (
    "                                111",
    "                                1111           111                     1111",
    "       111                      111         1111111                    1111",
    "       1111                    1111     11111111111          1111      1111",
    "       111                     111 1111111111111             1111      1111",
    "       111                    1111 1111111111                1111      1111",
    "       111   1    11          111   1111  111                1111      1111",
    "       1111111   11111       1111         111                1111      111111111",
    " 1111111111111   111111      1111         111                1111111111111111111",
    " 111111111111      11111    11111         111           111111111111111111111111",
    "  11111111          1111   111111         111          11111111111111111111",
    "       111            1    111111         111           111111111      111",
    "       111                 11 111  111111111111111111   11   1111      111",
    "       111  11111111        1 111 1111111111111111111        1111      111",
    "       11111111111111         111 1111111111111111111        111       111",
    "       111111111111111        111         111                1111   111111",
    "     1111111       111        111         111                1111   11111",
    "   1111111         1111       111         111                1111   1111",
    " 111111111         1111       111         111                1111",
    "111111 111         1111       111         111                 111",
    "11111  111        11111       111         111                 1111        11",
    " 111111111   111111111        111         111                 111111111111111",
    "     11111    1111111         111         1111111111111        11111111111111",
    "      1111    111111          111  11111111111111111            111111111111",
    "       111                    111  11111111111111111",
    "                              111",
)

def render_bitmap(bitmap, scale=1, color=(157, 124, 216)):
    pixels = {}
    for gy, row in enumerate(bitmap):
        for gx, bit in enumerate(row):
            if bit != " ":
                for sy in range(scale):
                    for sx in range(scale):
                        pixels[(gx * scale + sx, gy * scale + sy)] = (*color, 255)
    w = max((x + 1 for x, _ in pixels), default=1)
    h = max((y + 1 for _, y in pixels), default=1)
    def fn(x, y):
        return pixels.get((x, y), (0, 0, 0, 0))
    return fn, w, h

def render_wordmark(text, scale=5, colors=None):
    colors = colors or {}
    pixels = {}
    x_cursor = 0
    height = len(next(iter(GLYPHS.values()))) * scale
    for ch in text:
        glyph = GLYPHS.get(ch, GLYPHS[" "])
        color = colors.get(ch, colors.get("*", (205, 214, 244)))
        for gy, row in enumerate(glyph):
            for gx, bit in enumerate(row):
                if bit != " ":
                    for sy in range(scale):
                        for sx in range(scale):
                            px = x_cursor + gx * scale + sx
                            py = gy * scale + sy
                            pixels[(px, py)] = (*color, 255)
        x_cursor += (len(glyph[0]) + 1) * scale
    width = max((x + 1 for x, _ in pixels), default=1)
    def fn(x, y):
        return pixels.get((x, y), (0, 0, 0, 0))
    return fn, width, height

def write_logo(path):
    blue = (122, 162, 247)
    gold = (255, 206, 173)
    purple = (157, 124, 216)
    colors = {"O": blue, "M": blue, "I": blue, "S": gold, "U": gold}
    main_fn, mw, mh = render_wordmark("OMISU", scale=6, colors=colors)
    sub_fn, sw, sh = render_bitmap(OMAKASE_BITMAP, scale=1, color=purple)
    pad_x, gap = 24, 14
    w = max(mw, sw) + pad_x * 2
    h = mh + sh + gap + pad_x
    ox = (w - mw) // 2
    sub_ox = (w - sw) // 2
    oy = pad_x // 2
    sub_oy = oy + mh + gap

    def fn(x, y):
        if oy <= y < oy + mh and ox <= x < ox + mw:
            c = main_fn(x - ox, y - oy)
            if c[3]:
                return c
        if sub_oy <= y < sub_oy + sh and sub_ox <= x < sub_ox + sw:
            c = sub_fn(x - sub_ox, y - sub_oy)
            if c[3]:
                return c
        return (0, 0, 0, 0)

    write_png(path, w, h, fn)

bullet_fn = circle(7, 7, 5)
DARK = (26, 27, 38)
BORDER = (169, 177, 214)
RED = (247, 118, 142)
entry_fn = entry_box(1, 1, 278, 46, 8, DARK, BORDER)
entry_failed_fn = entry_box(1, 1, 278, 46, 8, DARK, RED)
lock_fn = lambda x, y: (
    (255, 255, 255, 255)
    if (
        (10 <= x <= 13 and 4 <= y <= 10)
        or (6 <= x <= 17 and 10 <= y <= 24)
        or (8 <= x <= 15 and 24 <= y <= 28)
    )
    else (0, 0, 0, 0)
)
lock_failed_fn = tint(lock_fn, RED)

shared = {
    "bullet.png": bullet_fn,
    "entry.png": entry_fn,
    "lock.png": lock_fn,
    "entry-failed.png": entry_failed_fn,
    "lock-failed.png": lock_failed_fn,
}

for name, fn in shared.items():
    if "bullet" in name:
        write_png(os.path.join(plymouth, name), 14, 14, fn)
    elif "entry" in name:
        write_png(os.path.join(plymouth, name), 280, 48, fn)
    elif "lock" in name:
        write_png(os.path.join(plymouth, name), 24, 32, fn)

for name, fn in shared.items():
    shutil.copy2(os.path.join(plymouth, name), os.path.join(sddm, name))

write_png(f"{plymouth}/progress_box.png", 420, 14, rect(0, 0, 419, 13, 6))
write_png(f"{plymouth}/progress_bar.png", 400, 6, rect(0, 0, 399, 5, 2))
write_png(f"{plymouth}/progress_glow.png", 400, 10, lambda x, y: (
    (255, 255, 255, 70) if 2 <= y <= 7 else (0, 0, 0, 0)
))
write_png(f"{plymouth}/wave1.png", 520, 28, wave_band(520, 28, 7, 140, 3, 190))
write_png(f"{plymouth}/wave2.png", 460, 22, wave_band(460, 22, 5, 110, 2, 150))
write_png(f"{plymouth}/wave3.png", 560, 18, wave_band(560, 18, 4, 90, 2, 120))
write_png(f"{plymouth}/rain_drop.png", 2, 18, lambda x, y: (
    (255, 255, 255, 180 if y < 14 else int(180 * (18 - y) / 4))
    if x == 0 or x == 1
    else (0, 0, 0, 0)
))
write_png(f"{plymouth}/flash.png", 4, 4, lambda x, y: (255, 255, 255, 255))

logo_path = f"{plymouth}/logo.png"
if os.path.isfile(logo_path):
    print(f"Keeping existing Plymouth logo at {logo_path}")
else:
    write_logo(logo_path)
shutil.copy2(logo_path, f"{sddm}/logo.png")

print(f"Wrote OmiSu branding PNGs under {plymouth} and {sddm}")
PY

python3 "$ROOT/scripts/gen-plymouth-wordmark.py"
if [[ -f "$PLYMOUTH/logo.png" ]]; then
  cp -f "$PLYMOUTH/logo.png" "$SDDM/logo.png"
fi
