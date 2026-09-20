#!/usr/bin/env bash
# Reset OmiSU local state so the first-run setup wizard appears again.
# Safe for Linux desktop preview (flutter run -d linux).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

USER_DATA="$ROOT/user-data"
BACKUP="$ROOT/user-data.backup"
PREFS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/com.omisu.launcher"
LEGACY_PREFS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/com.neogamelab.neostation"

usage() {
  cat <<'EOF'
Usage: scripts/reset-fresh-install.sh [--restore]

  (no args)  Back up user-data/ and clear first-run flags (setup wizard on next launch)
  --restore  Restore user-data/ from user-data.backup/ and quit

Examples:
  scripts/reset-fresh-install.sh
  scripts/preview-linux.sh --fresh
  scripts/reset-fresh-install.sh --restore
EOF
}

restore_backup() {
  if [[ ! -d "$BACKUP" ]]; then
    echo "No backup found at: $BACKUP" >&2
    exit 1
  fi
  if [[ -d "$USER_DATA" ]]; then
    rm -rf "$USER_DATA"
  fi
  mv "$BACKUP" "$USER_DATA"
  echo "Restored user-data from backup."
}

reset_state() {
  if [[ -d "$USER_DATA" ]]; then
    if [[ -d "$BACKUP" ]]; then
      STAMP="$(date +%Y%m%d-%H%M%S)"
      mv "$BACKUP" "${BACKUP}.${STAMP}"
      echo "Rotated old backup to: ${BACKUP}.${STAMP}"
    fi
    mv "$USER_DATA" "$BACKUP"
    echo "Backed up user-data -> user-data.backup/"
  else
    echo "No user-data/ directory (already fresh)."
  fi

  if [[ -f "$PREFS_DIR/shared_preferences.json" ]]; then
    rm -f "$PREFS_DIR/shared_preferences.json"
    echo "Cleared: $PREFS_DIR/shared_preferences.json"
  fi

  if [[ -f "$LEGACY_PREFS_DIR/shared_preferences.json" ]]; then
    rm -f "$LEGACY_PREFS_DIR/shared_preferences.json"
    echo "Cleared legacy NeoStation prefs: $LEGACY_PREFS_DIR/shared_preferences.json"
  fi

  echo
  echo "Fresh install state ready. Next launch will show the setup wizard."
  echo "Run: scripts/preview-linux.sh"
}

case "${1:-}" in
  --restore) restore_backup ;;
  -h|--help) usage ;;
  "") reset_state ;;
  *)
    echo "Unknown option: $1" >&2
    usage >&2
    exit 1
    ;;
esac
