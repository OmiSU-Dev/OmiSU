#!/usr/bin/env bash
# Symlink libretro-database cht/ into Nordi user-data for built-in cheat lookup.
#
# Usage (from repo root):
#   ./Nordi/scripts/install_libretro_cheats.sh
#   ./Nordi/scripts/install_libretro_cheats.sh /path/to/user-data
#
# Expects libretro-database-master/cht next to this repo (OmiSU/libretro-database-master).

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$ROOT/libretro-database-master/cht"
DEST="${1:-$HOME/.neostation/user-data/libretro-database/cht}"

if [[ ! -d "$SRC" ]]; then
  echo "Missing cheat source: $SRC" >&2
  echo "Clone https://github.com/libretro/libretro-database into $ROOT/libretro-database-master" >&2
  exit 1
fi

mkdir -p "$(dirname "$DEST")"
if [[ -e "$DEST" && ! -L "$DEST" ]]; then
  echo "Refusing to replace non-symlink: $DEST" >&2
  exit 1
fi
ln -sfn "$SRC" "$DEST"
echo "Linked $DEST -> $SRC"
