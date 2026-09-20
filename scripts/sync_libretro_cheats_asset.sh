#!/usr/bin/env bash
# Pack libretro-database cht/ into Nordi Flutter assets for onboard cheat import.
#
# Usage (from repo root):
#   ./Nordi/scripts/sync_libretro_cheats_asset.sh
#
# Requires: libretro-database-master/cht next to Nordi (OmiSU/libretro-database-master).

set -euo pipefail
NORDI="$(cd "$(dirname "$0")/.." && pwd)"
MONO="$(cd "$NORDI/.." && pwd)"
SRC=""
if [[ -d "$MONO/libretro-database-master/cht" ]]; then
  SRC="$MONO/libretro-database-master/cht"
elif [[ -d "$NORDI/../libretro-database-master/cht" ]]; then
  SRC="$(cd "$NORDI/.." && pwd)/libretro-database-master/cht"
fi
OUT="$NORDI/assets/data/libretro_cheats.tar.gz"

if [[ -z "$SRC" || ! -d "$SRC" ]]; then
  if [[ -f "$OUT" ]]; then
    echo "No libretro-database checkout; keeping existing $OUT"
    exit 0
  fi
  echo "Missing libretro-database cht/ and no $OUT" >&2
  echo "Clone https://github.com/libretro/libretro-database into libretro-database-master next to Nordi, or commit $OUT" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"
echo "Packing $SRC -> $OUT"
tar -czf "$OUT" -C "$SRC" .
ls -lh "$OUT"
