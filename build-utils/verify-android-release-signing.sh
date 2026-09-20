#!/usr/bin/env bash
# Confirms store/key passwords unlock the release keystore (same checks CI signing needs).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KS="${KEYSTORE_PATH:-$HOME/secrets/omisu-release.jks}"
if [[ "$KS" == ~* ]]; then KS="${KS/#\~/$HOME}"; fi
ALIAS="${KEY_ALIAS:-upload}"
B64="${NORDI_KEYSTORE_B64:-$ROOT/release/.android-keystore-base64.txt}"

if [[ ! -f "$KS" ]]; then
  echo "error: keystore not found: $KS (set KEYSTORE_PATH)" >&2
  exit 1
fi

read_properties() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  STORE="$(sed -n 's/^storePassword=//p' "$file" | head -1 | tr -d '\r')"
  KEY="$(sed -n 's/^keyPassword=//p' "$file" | head -1 | tr -d '\r')"
  ALIAS="$(sed -n 's/^keyAlias=//p' "$file" | head -1 | tr -d '\r')"
  [[ -n "$ALIAS" ]] || ALIAS="upload"
}

if [[ -n "${KEYSTORE_PASSWORD:-}" && -n "${KEY_PASSWORD:-}" ]]; then
  STORE="$KEYSTORE_PASSWORD"
  KEY="$KEY_PASSWORD"
elif read_properties "$ROOT/android/key.properties"; then
  echo "Using passwords from android/key.properties"
else
  read -rsp "Keystore store password: " STORE
  echo
  read -rsp "Key password (Enter if same as store): " KEY
  echo
  KEY="${KEY:-$STORE}"
fi

if ! keytool -list -keystore "$KS" -alias "$ALIAS" -storepass "$STORE" >/dev/null 2>&1; then
  echo "error: store password wrong for $KS (alias=$ALIAS)." >&2
  echo "  Fix storePassword in android/key.properties (must match keytool -list prompt)." >&2
  exit 1
fi
echo "OK: store password unlocks $KS (alias=$ALIAS)"

if ! keytool -list -keystore "$KS" -alias "$ALIAS" -storepass "$STORE" -keypass "$KEY" >/dev/null 2>&1; then
  echo "warning: keyPassword does not match keytool -keypass (store password is OK)." >&2
  echo "  If CI signing still fails, set keyPassword to the key's real password or run:" >&2
  echo "  keytool -keypasswd -keystore \"\$KEYSTORE_PATH\" -alias $ALIAS -storepass ... -keypass ... -new <same-as-store>" >&2
fi

if [[ -f "$B64" ]]; then
  DEC="$(mktemp)"
  base64 -d "$B64" > "$DEC"
  if cmp -s "$KS" "$DEC"; then
    echo "OK: $B64 decodes to the same bytes as $KS"
  else
    echo "error: $B64 does not match $KS — re-run prepare-github-keystore-secret.sh and update ANDROID_KEYSTORE_BASE64" >&2
    rm -f "$DEC"
    exit 1
  fi
  rm -f "$DEC"
fi

echo ""
echo "If CI still fails signing, re-push password secrets from key.properties:"
echo "  bash build-utils/push-github-android-password-secrets.sh"
