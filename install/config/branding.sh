#!/usr/bin/env bash
# OmiSu boot/login branding for Arch (Plymouth, SDDM, Limine labels).
set -euo pipefail

OMISU_SRC="${OMISU_SRC:-${OMISU_PATH:-/usr/share/omisu}}"

# Prefer the tty wordmark renderer (logo.txt art). generate-branding-pngs only
# supplies the other Plymouth PNGs and uses block glyphs that read like Omarchy.
if [[ -f "$OMISU_SRC/scripts/gen-logo.py" ]]; then
  python3 "$OMISU_SRC/scripts/gen-logo.py" 2>/dev/null || true
fi

if [[ -f "$OMISU_SRC/scripts/generate-branding-pngs.sh" ]]; then
  bash "$OMISU_SRC/scripts/generate-branding-pngs.sh"
fi

if [[ -d "$OMISU_SRC/default/sddm/omisu" ]]; then
  install -d -m 0755 /usr/share/sddm/themes/omisu
  cp -a "$OMISU_SRC/default/sddm/omisu/." /usr/share/sddm/themes/omisu/
fi

if [[ -f "$OMISU_SRC/default/sddm/hyprland.lua" ]]; then
  install -d -m 0755 /usr/share/sddm
  install -m 0644 "$OMISU_SRC/default/sddm/hyprland.lua" /usr/share/sddm/hyprland.lua
fi

if [[ -f "$OMISU_SRC/default/wayland-sessions/omisu.desktop" ]]; then
  install -d -m 0755 /usr/local/share/wayland-sessions
  install -m 0644 "$OMISU_SRC/default/wayland-sessions/omisu.desktop" \
    /usr/local/share/wayland-sessions/omisu.desktop
fi

if [[ -d "$OMISU_SRC/default/plymouth" ]]; then
  install -d -m 0755 /usr/share/plymouth/themes/omisu
  find "$OMISU_SRC/default/plymouth" -maxdepth 1 -type f -exec \
    install -m 0644 {} /usr/share/plymouth/themes/omisu/ \;
fi

# Same as Omarchy's omarchy-refresh-plymouth: publish the theme directory
# and point plymouthd.conf at it. The UKI rebuild is finalize_limine_boot /
# limine-mkinitcpio, not a mid-install mkinitcpio -P.
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
  plymouth-set-default-theme omisu 2>/dev/null || true
fi

# The plymouth hook packs Theme= from plymouthd.conf (omisu), but plymouthd
# still reads plymouthd.defaults (upstream Theme=bgrt). bgrt is not in the
# UKI, so the daemon dies and encrypt falls back to the text LUKS prompt.
if [[ -f /usr/share/plymouth/plymouthd.defaults ]]; then
  sed -i 's/^Theme=.*/Theme=omisu/' /usr/share/plymouth/plymouthd.defaults
fi

if [[ -x "$OMISU_SRC/bin/omisu-plymouth-set" ]] && [[ -f "$OMISU_SRC/default/plymouth/logo.png" ]]; then
  "$OMISU_SRC/bin/omisu-plymouth-set" '#241734' '#ffce5c' \
    "$OMISU_SRC/default/plymouth/logo.png"
fi

if [[ -d /usr/share/plymouth/themes/omarchy ]]; then
  rm -rf /usr/share/plymouth/themes/omarchy
fi

if [[ -f /etc/default/limine ]] && [[ -f "$OMISU_SRC/default/limine/default.conf" ]]; then
  sed -i 's/^OMARCHY/OmiSu/g; s/Omarchy/OmiSu/g' /etc/default/limine 2>/dev/null || true
fi
