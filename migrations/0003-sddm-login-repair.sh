#!/usr/bin/env bash
# Repair SDDM login on installed systems: known-good PAM stack for
# sddm/sddm-autologin/sddm-greeter, faillock cap, refreshed theme, and
# removal of the stale placeholder "omisu" account when a real owner exists.
set -euo pipefail
OMISU_SRC=/usr/share/omisu

# PAM stack + faillock cap (idempotent — sddm.sh rewrites only when needed).
OMISU_ENABLE_SDDM=1 bash "$OMISU_SRC/install/login/sddm.sh" || true

# Refresh the greeter theme (username display + reliable Enter handling).
if [[ -d "$OMISU_SRC/default/sddm/omisu" ]]; then
  install -d -m 0755 /usr/share/sddm/themes/omisu
  cp -a "$OMISU_SRC/default/sddm/omisu/." /usr/share/sddm/themes/omisu/
fi

# Remove the image's placeholder account when a real owner exists alongside
# it — the greeter can otherwise authenticate against the locked placeholder.
if id omisu &>/dev/null; then
  while IFS=: read -r name _ uid _; do
    if (( uid >= 1000 )) && [[ $name != omisu && $name != nobody ]]; then
      userdel -r omisu 2>/dev/null || userdel omisu 2>/dev/null || true
      break
    fi
  done < /etc/passwd
fi

# Clear any accumulated faillock counters so a correct password works now.
if command -v faillock >/dev/null 2>&1; then
  faillock --reset 2>/dev/null || true
fi

echo "OmiSu: repaired SDDM PAM stack, theme, and placeholder account."
