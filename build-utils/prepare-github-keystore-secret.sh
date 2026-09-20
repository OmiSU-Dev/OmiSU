#!/usr/bin/env bash
# Writes base64(keystore) to a file for pasting into GitHub Production secret
# ANDROID_KEYSTORE_BASE64. Does not print the secret to the terminal.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEYSTORE="${KEYSTORE_PATH:-}"
if [[ -n "$KEYSTORE" && "$KEYSTORE" == ~* ]]; then
  KEYSTORE="${KEYSTORE/#\~/$HOME}"
fi

if [[ -z "$KEYSTORE" ]]; then
  for candidate in \
    "$HOME/secrets/omisu-release.jks" \
    "$ROOT/android/app/release.jks" \
    "$ROOT/release.jks" \
    "$ROOT/android/release.jks"; do
    if [[ -f "$candidate" ]]; then
      KEYSTORE="$candidate"
      break
    fi
  done
fi

if [[ -z "$KEYSTORE" || ! -f "$KEYSTORE" ]]; then
  echo "error: set KEYSTORE_PATH to your release.jks (same key as Wi‑Fi deploy)." >&2
  echo "  example: KEYSTORE_PATH=~/secrets/omisu-release.jks $0" >&2
  exit 1
fi

OUT="${NORDI_KEYSTORE_B64_OUT:-$ROOT/release/.android-keystore-base64.txt}"
mkdir -p "$(dirname "$OUT")"
base64 -w0 "$KEYSTORE" > "$OUT"
chmod 600 "$OUT"

echo "Wrote base64 keystore to: $OUT"
echo "GitHub → Settings → Environments → Production → ANDROID_KEYSTORE_BASE64"
echo "Paste the entire file contents as the secret value (one line)."
echo "Also add ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD."
