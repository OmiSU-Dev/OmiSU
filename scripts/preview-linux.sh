#!/usr/bin/env bash
# Launch OmiSU on Linux desktop for development testing before Android installs.
#
# Works here: setup wizard, ROM scan, library UI, artwork scrape, navigation.
# Play on Linux: external RetroArch (e.g. Flatpak org.libretro.RetroArch).
# In-app libretro cores (LibretroDroid): Android APK only.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FRESH=0
EXTRA_ARGS=()

usage() {
  cat <<'EOF'
Usage: scripts/preview-linux.sh [--fresh] [flutter run args...]

  --fresh   Reset to first-run state (setup wizard) before launching
  --help    Show this help

Examples:
  scripts/preview-linux.sh
  scripts/preview-linux.sh --fresh
  scripts/preview-linux.sh --fresh --release

While running: r = hot reload, R = hot restart, q = quit
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fresh)
      FRESH=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

resolve_flutter() {
  if [[ -x "$ROOT/.fvm/flutter_sdk/bin/flutter" ]]; then
    echo "$ROOT/.fvm/flutter_sdk/bin/flutter"
  elif command -v fvm >/dev/null 2>&1; then
    echo "fvm flutter"
  elif command -v flutter >/dev/null 2>&1; then
    echo "flutter"
  else
    echo "Flutter not found. Install FVM and run: fvm install 3.47.4" >&2
    exit 1
  fi
}

FLUTTER="$(resolve_flutter)"

if [[ "$FRESH" -eq 1 ]]; then
  "$ROOT/scripts/reset-fresh-install.sh"
  echo
fi

echo "Project: $ROOT"
echo "Flutter: $FLUTTER"
echo "Target:  linux (dev preview — play needs RetroArch; APK has built-in cores)"
echo

# shellcheck disable=SC2086
exec $FLUTTER run -d linux "${EXTRA_ARGS[@]}"
