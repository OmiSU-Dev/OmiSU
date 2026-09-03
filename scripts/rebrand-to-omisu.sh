#!/usr/bin/env bash
# Mechanical omisu -> omisu rebrand for the Arch fork.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

OMISU_KEEP=(
  bin/omisu-theme
  bin/omisu-wallpaper-gen.py
  bin/omisu-heal
  bin/omisu-docto
  bin/omisu-migrate
  bin/omisu-agent
  bin/omisu-agents
  bin/omisu-default-agent
  bin/omisu-branding-about-animation
  bin/omisu-branding-screensave
  bin/omisu-launch-about
  bin/omisu-screensave
  bin/omisu-screensaver-storm.py
  bin/omisu-launch-screensave
  bin/omisu-plymouth-set
  bin/omisu-plymouth-set-by-theme
  bin/omisu-installer-banne
  logo.txt
  lib/theme.sh
  themes/flat
  wallpapers
  default/plymouth/omisu.plymouth
  default/plymouth/omisu.script
  default/sddm/omisu
  default/omisu
  default/installer/banner.txt
  default/wayland-sessions/omisu.desktop
  config/omisu
  migrations/0001-example.sh
  migrations/0002-omisu-branding-logo.sh
  migrations/0003-sddm-login-repair.sh
)

keep_path() {
  local p="$1"
  for k in "${OMISU_KEEP[@]}"; do
    [[ "$p" == "$k" || "$p" == "$k/"* ]] && return 0
  done
  return 1
}

echo "Removing obsolete OmiSu branding..."
rm -f default/plymouth/omisu.plymouth default/plymouth/omisu.script
rm -rf default/sddm/omisu
rm -f default/wayland-sessions/omisu.desktop

echo "Renaming paths (deepest first)..."
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  keep_path "$path" && continue
  new="${path//omisu/omisu}"
  [[ "$path" == "$new" ]] && continue
  if [[ -e "$new" ]]; then
    echo "  skip rename (target exists): $path -> $new"
    rm -rf "$path" 2>/dev/null || rm -f "$path" 2>/dev/null || true
  else
    mkdir -p "$(dirname "$new")"
    git mv "$path" "$new" 2>/dev/null || mv "$path" "$new"
    echo "  $path -> $new"
  fi
done < <(find . -depth -name '*omisu*' ! -path './.git/*' | sort -r)

echo "Replacing text content..."
while IFS= read -r -d '' file; do
  case "$file" in
    *.png|*.jpg|*.jpeg|*.gif|*.webp|*.ico|*.ttf|*.woff|*.woff2|*.raw|*.qcow2|*.iso|*.gz|*.zip)
      continue ;;
  esac
  if ! grep -qE 'omisu|OMISU|OmiSu' "$file" 2>/dev/null; then
    continue
  fi
  sed -i \
    -e 's/OmiSu/OmiSu/g' \
    -e 's/OMISU/OMISU/g' \
    -e 's/omisu/omisu/g' \
    "$file"
done < <(find . -type f ! -path './.git/*' -print0)

echo "Rebrand pass complete."
