#!/usr/bin/env python3
"""Rasterize お任せ with a CJK system font into a 1-bit bitmap suitable for
embedding in generate-branding-pngs.sh (which must stay stdlib-only)."""
from PIL import Image, ImageDraw, ImageFont

TEXT = "お任せ"
SIZE = 28

font = None
for path in (
    r"C:\Windows\Fonts\YuGothB.ttc",
    r"C:\Windows\Fonts\YuGothM.ttc",
    r"C:\Windows\Fonts\msgothic.ttc",
    r"C:\Windows\Fonts\meiryo.ttc",
):
    try:
        font = ImageFont.truetype(path, SIZE)
        break
    except OSError:
        continue
assert font, "no CJK font found"

bbox = font.getbbox(TEXT)
w = bbox[2] - bbox[0] + 4
h = bbox[3] - bbox[1] + 4
img = Image.new("L", (w, h), 0)
d = ImageDraw.Draw(img)
d.text((2 - bbox[0], 2 - bbox[1]), TEXT, fill=255, font=font)

# Trim empty margins, then threshold.
px = img.load()
xs = [x for x in range(w) for y in range(h) if px[x, y] > 96]
ys = [y for y in range(h) for x in range(w) if px[x, y] > 96]
x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)

rows = []
for y in range(y0, y1 + 1):
    rows.append("".join("1" if px[x, y] > 96 else " " for x in range(x0, x1 + 1)))

from pathlib import Path

out = [f"# omakase bitmap {len(rows[0])}x{len(rows)}", "OMAKASE_BITMAP = ("]
out += [f'    "{r.rstrip()}",' for r in rows]
out.append(")")
Path(__file__).with_name("omakase-bitmap.txt").write_text(
    "\n".join(out) + "\n", encoding="utf-8", newline="\n"
)
print(f"bitmap {len(rows[0])}x{len(rows)}")
