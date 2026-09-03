#!/usr/bin/env python3
# omisu:summary=Storm screensaver that rain-writes the OmiSu wordmark on screen.
#
# omisu-screensaver-storm — a rain/thunderstorm screensaver that "writes" OmiSU.
#
# Matrix-style rain falls down the screen. Where a droplet passes a cell of the
# OmiSU logo, it stamps the letter into place — so the logo is gradually
# rain-written across the screen. Periodic lightning flashes illuminate it, and
# once the whole word is written it holds, then the rain washes it away and
# rewrites it. Any key press or signal exits.
#
# Self-contained (curses); no external effect tool required.

import curses
import os
import random
import signal
import sys
import time

LOGO_PATHS = (
    os.path.expanduser("~/.config/omisu/logo.txt"),
    "/usr/share/omisu/logo.txt",
    "/etc/skel/.config/omisu/logo.txt",
)

DEFAULT_LOGO = r"""
 ▄▄▄
  ▄█████▄ ███▄ ▄███▄ ███▄ ▄███▄ ███▄
 ███   ███ ██████████ ██████████ ███
 ███   ███ ███  ███  ███  ███  ███
 ███   ███ ███  ███  ███  ███  ███
 ███   ███ ███  ███  ███  ███  ███
 ███   ███ ███  ███  ███  ███  ███
  ▀█████▀  ▀▀▀  ▀▀▀  ▀▀▀  ▀▀▀  ▀▀▀

                omiSU
"""


def load_logo():
    for p in LOGO_PATHS:
        try:
            with open(p, "r", encoding="utf-8") as f:
                return f.read()
        except OSError:
            continue
    return DEFAULT_LOGO


def hex_to_rgb(h):
    h = h.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    try:
        return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
    except ValueError:
        return None


def nearest_curses(rgb, max_colors):
    if rgb is None:
        return -1
    r, g, b = rgb
    best, bestd = -1, 1e9
    for c in range(16, max_colors):
        cr = (c >> 16) & 0xFF if max_colors > 256 else 0
        # Fallback: use predefined palette for small terminals.
        if max_colors <= 256:
            # approximate by hue buckets
            cr, cg, cb = (0, 0, 0)
        try:
            cc = curses.color_content(c)
            d = (cc[0] - r) ** 2 + (cc[1] - g) ** 2 + (cc[2] - b) ** 2
        except curses.error:
            continue
        if d < bestd:
            bestd, best = d, c
    return best


def setup_colors(stdscr):
    accent = hex_to_rgb(os.environ.get("OMISU_ACCENT", "#cba6f7"))
    fg = hex_to_rgb(os.environ.get("OMISU_FG", "#cdd6f4"))
    has_ext = curses.can_change_color() and curses.COLORS >= 256
    if has_ext:
        scale = 1000 // 255
        for i, rgb in enumerate(((120, 220, 150), (60, 140, 90),
                                 accent or (180, 140, 255),
                                 fg or (220, 220, 235),
                                 (255, 255, 255)), start=1):
            try:
                curses.init_color(i + 10, rgb[0] * scale, rgb[1] * scale, rgb[2] * scale)
            except curses.error:
                pass
        curses.init_pair(1, 11, 0)   # rain bright (green)
        curses.init_pair(2, 12, 0)   # rain dim
        curses.init_pair(3, 13, 0)   # logo (accent)
        curses.init_pair(4, 14, 0)   # logo glow/fg
        curses.init_pair(5, 15, 0)   # lightning white
    else:
        curses.init_pair(1, curses.COLOR_GREEN, curses.COLOR_BLACK)
        curses.init_pair(2, curses.COLOR_GREEN, curses.COLOR_BLACK)
        curses.init_pair(3, curses.COLOR_MAGENTA, curses.COLOR_BLACK)
        curses.init_pair(4, curses.COLOR_WHITE, curses.COLOR_BLACK)
        curses.init_pair(5, curses.COLOR_WHITE, curses.COLOR_BLACK)


RAIN_CHARS = "ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾙﾚﾛ0123456789#$%&*+<>=@"


class Storm:
    def __init__(self, stdscr):
        self.s = stdscr
        self.h, self.w = stdscr.getmaxyx()
        self.build_logo()
        self.reset_drops()
        self.written = {}
        self.flash = 0
        self.phase = "raining"
        self.phase_until = time.time() + 7.0
        self.bolt = None

    def build_logo(self):
        text = load_logo()
        lines = [ln.rstrip("\n") for ln in text.split("\n")]
        lines = [ln for ln in lines if ln.strip() != ""]
        # Original OmiSu touch: a rain-written tagline under the wordmark.
        tagline = "  · openSUSE Tumbleweed ·  "
        lines.append("")
        lines.append(tagline)
        self.logo_rows = len(lines)
        self.logo_cols = max((len(ln) for ln in lines), default=0)
        top = max(0, (self.h - self.logo_rows) // 2)
        left = max(0, (self.w - self.logo_cols) // 2)
        self.logo = {}          # (y, x) -> char
        self.logo_at = {}       # x -> [y, ...]
        self.tagline_rows = {len(lines) - 1}  # rows that are the tagline
        for ry, ln in enumerate(lines):
            for cx, ch in enumerate(ln):
                if ch == " ":
                    continue
                y = top + ry
                x = left + cx
                if 0 <= y < self.h and 0 <= x < self.w:
                    self.logo[(y, x)] = ch
                    self.logo_at.setdefault(x, []).append(y)
        for x in self.logo_at:
            self.logo_at[x].sort()

    def reset_drops(self):
        self.drops = {}
        for x in range(self.w):
            self.drops[x] = {
                "y": random.uniform(-self.h, 0),
                "speed": random.uniform(0.35, 0.9),
                "prev": -999,
            }

    def resize(self):
        self.h, self.w = self.s.getmaxyx()
        self.build_logo()
        self.reset_drops()
        self.written = {}

    def on_key(self):
        return True

    def frame(self):
        self.s.erase()
        now = time.time()

        # Lightning trigger
        if self.flash <= 0 and random.random() < 0.004:
            self.flash = 3
            self.bolt = self.make_bolt()

        # Advance + draw rain
        for x, d in self.drops.items():
            d["prev"] = d["y"]
            d["y"] += d["speed"]
            hy = int(d["y"])
            # stamp logo cells the head just passed
            for ly in self.logo_at.get(x, []):
                if d["prev"] < ly <= d["y"] and (ly, x) not in self.written:
                    self.written[(ly, x)] = self.logo[(ly, x)]
                    if random.random() < 0.25:
                        self.flash = max(self.flash, 2)
            if hy >= self.h:
                d["y"] = random.uniform(-4, 0)
                d["speed"] = random.uniform(0.35, 0.9)
                continue
            # draw head + short trail
            if 0 <= hy < self.h:
                self.s.addstr(hy, x, random.choice(RAIN_CHARS),
                              curses.color_pair(1) | curses.A_BOLD)
            for t in range(1, 4):
                ty = hy - t
                if 0 <= ty < self.h:
                    self.s.addstr(ty, x, random.choice(RAIN_CHARS),
                                  curses.color_pair(2))

        # Draw written logo — wordmark shimmers, tagline stays calm
        complete = len(self.written) == len(self.logo)
        pulse = (int(now * 2) % 2) == 0
        for (y, x), ch in self.written.items():
            if 0 <= y < self.h and 0 <= x < self.w:
                if y in self.tagline_rows:
                    attr = curses.color_pair(4)  # calm fg for tagline
                elif pulse:
                    attr = curses.color_pair(3) | curses.A_BOLD  # accent
                else:
                    attr = curses.color_pair(5) | curses.A_BOLD  # white flash
                self.s.addstr(y, x, ch, attr)

        # Phase transitions
        if self.phase == "raining" and complete:
            self.phase = "hold"
            self.phase_until = now + 5.0
        elif self.phase == "hold" and now >= self.phase_until:
            self.phase = "washing"
            self.phase_until = now + 2.5
            self.written = {}
            self.reset_drops()
        elif self.phase == "washing" and now >= self.phase_until:
            self.phase = "raining"
            self.phase_until = now + 7.0

        # Lightning flash overlay
        if self.flash > 0:
            self.flash -= 1
            # brighten the logo region + a bolt
            if self.bolt:
                for (y, x) in self.bolt:
                    if 0 <= y < self.h and 0 <= x < self.w:
                        try:
                            self.s.addstr(y, x, "#", curses.color_pair(5) | curses.A_BOLD)
                        except curses.error:
                            pass

        try:
            self.s.refresh()
        except curses.error:
            pass

        if self.flash == 0:
            self.bolt = None

    def make_bolt(self):
        bolt = []
        x = random.randint(0, self.w - 1)
        y = 0
        while y < self.h:
            bolt.append((y, x))
            y += 1
            x += random.choice((-1, 0, 1))
            x = max(0, min(self.w - 1, x))
        return bolt


def main(stdscr):
    curses.curs_set(0)
    stdscr.nodelay(True)
    stdscr.keypad(True)
    try:
        curses.cbreak()
    except curses.error:
        pass
    setup_colors(stdscr)

    storm = Storm(stdscr)

    def handle(signum, frame):
        raise KeyboardInterrupt

    signal.signal(signal.SIGINT, handle)
    signal.signal(signal.SIGTERM, handle)

    last = time.time()
    while True:
        try:
            ch = stdscr.getch()
        except curses.error:
            ch = -1
        if ch != -1:
            return
        h, w = stdscr.getmaxyx()
        if (h, w) != (storm.h, storm.w):
            storm.resize()
        storm.frame()
        # ~30 fps
        dt = 0.033 - (time.time() - last)
        if dt > 0:
            time.sleep(dt)
        last = time.time()


if __name__ == "__main__":
    try:
        curses.wrapper(main)
    except KeyboardInterrupt:
        pass
    # restore cursor
    try:
        curses.curs_set(1)
    except Exception:
        pass
    sys.exit(0)
