#!/usr/bin/env bash
# Stage OmiSu branding assets (never copy OmiSu wordmark PNGs into the image).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OM="$ROOT/omisu-quattro"

mkdir -p "$ROOT/default/plymouth" "$ROOT/default/sddm/omisu" \
  "$ROOT/default/grub/themes/omisu" "$ROOT/default/wayland-sessions" \
  "$ROOT/config/sddm.conf.d"

if [[ -f "$OM/default/sddm/hyprland.lua" ]]; then
  cp "$OM/default/sddm/hyprland.lua" "$ROOT/default/sddm/hyprland.lua"
fi

bash "$ROOT/scripts/generate-branding-pngs.sh"
echo "Staged OmiSu branding assets under $ROOT/default/"
