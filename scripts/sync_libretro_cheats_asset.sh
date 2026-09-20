#!/usr/bin/env bash
# Pack libretro-database cht/ into Nordi Flutter assets for onboard cheat import.
#
# Usage (from repo root):
#   ./Nordi/scripts/sync_libretro_cheats_asset.sh
#
# Requires: libretro-database-master/cht next to Nordi (OmiSU/libretro-database-master).

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$ROOT/libretro-database-master/cht"
OUT="$ROOT/Nordi/assets/data/libretro_cheats.tar.gz"

if [[ ! -d "$SRC" ]]; then
  echo "Missing: $SRC" >&2
  echo "Clone https://github.com/libretro/libretro-database into $ROOT/libretro-database-master" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"
echo "Packing $SRC -> $OUT"
tar -czf "$OUT" -C "$SRC" .
ls -lh "$OUT"
