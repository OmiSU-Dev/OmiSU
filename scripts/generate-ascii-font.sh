#!/usr/bin/env bash
# Generate Delta Corps Priest 1 glyph JSON from Omarchy omarchy-ascii.
# Run from repo root after omarchy-quattro is available as a sibling or via OMARCHY_PATH.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OMARCHY_PATH="${OMARCHY_PATH:-$(cd "$ROOT/../omarchy-quattro" 2>/dev/null && pwd || true)}"
OUT="$ROOT/assets/ascii/delta_corps_priest_1.json"

if [[ ! -x "$OMARCHY_PATH/bin/omarchy-ascii" ]]; then
  echo "Set OMARCHY_PATH to omarchy-quattro (contains bin/omarchy-ascii)" >&2
  exit 1
fi

export OMARCHY_PATH
python3 << PYEOF
import json, subprocess, os

omarchy = os.environ["OMARCHY_PATH"]
bin_path = f"{omarchy}/bin/omarchy-ascii"
chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ "
glyphs, widths = {}, {}
height = None

for ch in chars:
    key = "SPACE" if ch == " " else ch
    r = subprocess.run(
        ["bash", bin_path, ch],
        env={**os.environ, "OMARCHY_PATH": omarchy},
        capture_output=True, text=True,
    )
    lines = [ln.rstrip() for ln in r.stdout.splitlines()]
    while lines and not lines[-1].strip():
        lines.pop()
    if not lines:
        continue
    height = height or len(lines)
    glyphs[key] = lines
    widths[key] = max(len(ln) for ln in lines)

with open("$OUT", "w") as f:
    json.dump({"height": height or 8, "hardblank": "\$", "glyphs": glyphs, "widths": widths}, f, separators=(",", ":"))
print(f"Wrote $OUT ({len(glyphs)} glyphs)")
PYEOF
