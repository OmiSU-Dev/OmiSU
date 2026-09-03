#!/usr/bin/env python3
"""Retro OmiSU wordmark frames for the Plymouth sine-byte type-in."""
from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path

OMI = (137, 180, 250, 255)
SU = (158, 206, 106, 255)
SCALE = 10
GAP = 2
STEPS = 6

GLYPHS = {
    "O": [
        " XXX ",
        "X   X",
        "X   X",
        "X   X",
        "X   X",
        "X   X",
        " XXX ",
    ],
    "m": [
        "       ",
        "X XX X ",
        "XX  XX ",
        "X    X ",
        "X    X ",
        "X    X ",
        "X    X ",
    ],
    "i": [
        " X ",
        "   ",
        " X ",
        " X ",
        " X ",
        " X ",
        " X ",
    ],
    "S": [
        " XXXX",
        "X    ",
        "X    ",
        " XXX ",
        "    X",
        "    X",
        "XXXX ",
    ],
    "U": [
        "X   X",
        "X   X",
        "X   X",
        "X   X",
        "X   X",
        "X   X",
        " XXX ",
    ],
}
WORD = (("O", OMI), ("m", OMI), ("i", OMI), ("S", SU), ("U", SU))


def chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(
        ">I", zlib.crc32(tag + data) & 0xFFFFFFFF
    )


def write_png(path: Path, w: int, h: int, pixels: list[tuple[int, int, int, int]]) -> None:
    rows = []
    i = 0
    for _y in range(h):
        row = b"\x00"
        for _x in range(w):
            row += bytes(pixels[i])
            i += 1
        rows.append(row)
    raw = b"".join(rows)
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


def glyph_width(ch: str) -> int:
    return len(GLYPHS[ch][0]) * SCALE


def layout() -> list[tuple[int, str, tuple[int, int, int, int]]]:
    x = 0
    out = []
    for ch, color in WORD:
        out.append((x, ch, color))
        x += glyph_width(ch) + GAP * SCALE
    return out


def render_frame(upto: int, fill: float, phase: float) -> tuple[int, int, list[tuple[int, int, int, int]]]:
    placed = layout()
    last_x, last_ch, _ = placed[-1]
    width = last_x + glyph_width(last_ch)
    height = 7 * SCALE
    pixels = [(0, 0, 0, 0)] * (width * height)

    for index, (ox, ch, color) in enumerate(placed):
        gw = glyph_width(ch)
        if index < upto:
            letter_fill = 1.0
        elif index == upto:
            letter_fill = fill
        else:
            continue
        edge = gw * letter_fill
        for gy, row in enumerate(GLYPHS[ch]):
            for gx, cell in enumerate(row):
                if cell != "X":
                    continue
                for py in range(SCALE):
                    for px in range(SCALE):
                        x = ox + gx * SCALE + px
                        y = gy * SCALE + py
                        wobble = int(math.sin((y / SCALE) * 0.9 + phase) * SCALE * 0.4)
                        if x <= ox + edge + wobble:
                            pixels[y * width + x] = color
    return width, height, pixels


def main() -> None:
    dest = Path(__file__).resolve().parents[1] / "default/plymouth"
    dest.mkdir(parents=True, exist_ok=True)

    for letter in range(len(WORD)):
        for step in range(STEPS):
            w, h, pixels = render_frame(letter, (step + 1) / STEPS, step * 0.7)
            write_png(dest / f"wm_{letter}_{step}.png", w, h, pixels)

    last = dest / "wm_4_5.png"
    (dest / "logo.png").write_bytes(last.read_bytes())
    print(f"wrote {len(WORD) * STEPS} wordmark frames and logo.png under {dest}")


if __name__ == "__main__":
    main()
