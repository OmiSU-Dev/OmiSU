#!/usr/bin/env bash
# Replace stale boot/login branding with OmiSu assets.
set -euo pipefail
OMISU_SRC=/usr/share/omisu

if [[ -f "$OMISU_SRC/scripts/generate-branding-pngs.sh" ]]; then
  bash "$OMISU_SRC/scripts/generate-branding-pngs.sh"
fi

if [[ -x /usr/bin/omisu-plymouth-set ]] && [[ -f "$OMISU_SRC/default/plymouth/logo.png" ]]; then
  omisu-plymouth-set '#241734' '#ffce5c' "$OMISU_SRC/default/plymouth/logo.png" || true
fi

rm -rf /usr/share/plymouth/themes/omisu-stale 2>/dev/null || true
plymouth-set-default-theme omisu 2>/dev/null || true
if command -v mkinitcpio >/dev/null; then
  mkinitcpio -P 2>/dev/null || true
fi

echo "OmiSu: refreshed boot/login branding."
