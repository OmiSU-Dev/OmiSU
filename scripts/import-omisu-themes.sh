#!/usr/bin/env bash
# Generate OmiSu flat theme files from OmiSu colors.toml.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OMISU="$ROOT/omisu-quattro/themes"
OMISU="$ROOT/themes"

mkdir -p "$OMISU"

for dir in "$OMISU"/*/; do
  name=$(basename "$dir")
  toml="$dir/colors.toml"
  [[ -f $toml ]] || continue

  accent=$(awk -F'"' '/^accent =/ { print $2; exit }' "$toml" | tr -d '#')
  bg=$(awk -F'"' '/^background =/ { print $2; exit }' "$toml" | tr -d '#')
  fg=$(awk -F'"' '/^foreground =/ { print $2; exit }' "$toml" | tr -d '#')
  inactive=$(awk -F'"' '/^muted =/ { print $2; exit }' "$toml" | tr -d '#')
  [[ -z $inactive ]] && inactive=444444

  cat >"$OMISU/$name" <<EOF
ACCENT=$accent
BG=$bg
FG=$fg
INACTIVE=$inactive
EOF
  echo "Wrote $name"
done

if [[ -f $OMISU/tokyo-night ]]; then
  cp "$OMISU/tokyo-night" "$OMISU/tokyonight"
  echo "Synced tokyonight alias"
fi

echo "Total themes: $(find "$OMISU" -maxdepth 1 -type f | wc -l)"
