#!/usr/bin/env python3
"""Generate the tty OMISU wordmark in OmiSu's letter style.

Every glyph row must be exactly the glyph's declared width — uneven rows shear
the columns and turn the wordmark into mush on the console (seen as "on3S0").
The script asserts this before writing anything.

Also renders default/plymouth/logo.png for the Plymouth boot splash.
"""
from __future__ import annotations

from pathlib import Path

letters = {
    "O": [
        " ▄█████▄ ",
        "███   ███",
        "███   ███",
        "███   ███",
        "███   ███",
        "███   ███",
        "███   ███",
        " ▀█████▀ ",
    ],
    "M": [
        " ▄███████████▄ ",
        "███   ███   ███",
        "███   ███   ███",
        "███   ███   ███",
        "███   ███   ███",
        "███   ███   ███",
        "███   ███   ███",
        " ▀█   ███   █▀ ",
    ],
    "I": [
        "▄███████▄",
        "   ███   ",
        "   ███   ",
        "   ███   ",
        "   ███   ",
        "   ███   ",
        "   ███   ",
        "▀███████▀",
    ],
    "S": [
        " ▄██████▄",
        "███   ███",
        "███      ",
        " ▀█████▄ ",
        "      ███",
        "      ███",
        "███   ███",
        " ▀█████▀ ",
    ],
    "U": [
        " ▄█   █▄ ",
        "███   ███",
        "███   ███",
        "███   ███",
        "███   ███",
        "███   ███",
        "███   ███",
        " ▀█████▀ ",
    ],
}

PLYMOUTH_OMI_COLOR = (137, 180, 250, 255)  # #89b4fa — Tokyo Night blue
PLYMOUTH_SU_COLOR = (158, 206, 106, 255)  # #9ece6a — OmiSu green
FONT_CANDIDATES = (
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
    "/usr/share/fonts/TTF/DejaVuSansMono.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
)


def logo_split_index() -> int:
    gap = 2
    return (
        len(letters["O"][0])
        + gap
        + len(letters["M"][0])
        + gap
        + len(letters["I"][0])
    )


def build_wordmark() -> tuple[str, int]:
    height = 8
    for ch, rows in letters.items():
        assert len(rows) == height, f"{ch}: wrong height {len(rows)}"
        width = len(rows[0])
        for i, row in enumerate(rows):
            assert len(row) == width, f"{ch} row {i}: {len(row)} != {width}"

    word = "OMISU"
    gap = 2
    body = []
    for row in range(height):
        line = (" " * gap).join(letters[ch][row] for ch in word)
        body.append(line)

    width = len(body[0])
    assert all(len(line) == width for line in body), "wordmark rows uneven"

    m_start = len(letters["O"][0]) + gap
    m_width = len(letters["M"][0])
    cap_pad = m_start + (m_width - 3) // 2
    cap = " " * cap_pad + "▄▄▄"

    rows = [cap] + [line.rstrip() for line in body]
    return "\n".join(rows) + "\n", width


def load_mono_font(size: int):
    from PIL import ImageFont

    for path in FONT_CANDIDATES:
        candidate = Path(path)
        if candidate.is_file():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def write_plymouth_logo(root: Path, text: str) -> Path:
    from PIL import Image, ImageDraw

    split = logo_split_index()
    lines = text.rstrip("\n").split("\n")
    font = load_mono_font(13)
    probe = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    bbox = probe.textbbox((0, 0), "Ay", font=font)
    line_height = bbox[3] - bbox[1] + 2
    line_widths = []
    for row, line in enumerate(lines):
        if row == 0:
            line_widths.append(probe.textbbox((0, 0), line, font=font)[2])
        else:
            omi = line[:split]
            su = line[split:]
            line_widths.append(
                probe.textbbox((0, 0), omi, font=font)[2]
                + probe.textbbox((0, 0), su, font=font)[2]
            )
    text_width = max(line_widths)
    pad_x, pad_y = 8, 6

    image = Image.new(
        "RGBA",
        (text_width + pad_x * 2, line_height * len(lines) + pad_y * 2),
        (0, 0, 0, 0),
    )
    draw = ImageDraw.Draw(image)
    y = pad_y
    for row, line in enumerate(lines):
        if row == 0:
            draw.text((pad_x, y), line, fill=PLYMOUTH_OMI_COLOR, font=font)
        else:
            omi = line[:split]
            su = line[split:]
            omi_w = draw.textbbox((0, 0), omi, font=font)[2]
            draw.text((pad_x, y), omi, fill=PLYMOUTH_OMI_COLOR, font=font)
            draw.text((pad_x + omi_w, y), su, fill=PLYMOUTH_SU_COLOR, font=font)
        y += line_height

    crop = image.getbbox()
    if crop:
        image = image.crop(crop)

    out = root / "default/plymouth/logo.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    image.save(out, "PNG")
    return out


def main() -> None:
    text, width = build_wordmark()
    root = Path(__file__).resolve().parents[1]

    (root / "logo.txt").write_text(text, encoding="utf-8", newline="\n")

    kiwi_logo = root / "root/usr/share/omisu/logo.txt"
    kiwi_logo.parent.mkdir(parents=True, exist_ok=True)
    kiwi_logo.write_text(text, encoding="utf-8", newline="\n")

    plymouth_logo = write_plymouth_logo(root, text)
    print(
        f"wrote {len(text.splitlines())} logo lines (width {width}, split {logo_split_index()}), "
        f"plymouth logo {plymouth_logo} ({plymouth_logo.stat().st_size} bytes)"
    )


if __name__ == "__main__":
    main()
