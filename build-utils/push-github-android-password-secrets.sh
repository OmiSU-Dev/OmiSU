#!/usr/bin/env bash
# Upload ANDROID_* password secrets to GitHub Production from android/key.properties (no echo).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROPS="$ROOT/android/key.properties"
REPO="${GITHUB_REPO:-OmiSU-Dev/OmiSU}"
ENV_NAME="${GITHUB_ENVIRONMENT:-Production}"

if [[ ! -f "$PROPS" ]]; then
  echo "error: missing $PROPS — copy from android/key.properties.example and fill in real values." >&2
  exit 1
fi

read_prop() {
  local key="$1"
  sed -n "s/^${key}=//p" "$PROPS" | head -1 | tr -d '\r'
}

storePassword="$(read_prop storePassword)"
keyPassword="$(read_prop keyPassword)"
keyAlias="$(read_prop keyAlias)"
keyAlias="${keyAlias:-upload}"

if [[ -z "$storePassword" ]]; then
  echo "error: storePassword is missing in $PROPS (non-comment line: storePassword=...)" >&2
  exit 1
fi
if [[ -z "$keyPassword" ]]; then
  echo "error: keyPassword is missing in $PROPS" >&2
  exit 1
fi
if [[ "$storePassword" == YOUR_* || "$keyPassword" == YOUR_* ]]; then
  echo "error: replace YOUR_* placeholders in $PROPS with real passwords." >&2
  exit 1
fi

printf '%s' "$storePassword" | gh secret set ANDROID_KEYSTORE_PASSWORD --env "$ENV_NAME" --repo "$REPO"
printf '%s' "$keyPassword" | gh secret set ANDROID_KEY_PASSWORD --env "$ENV_NAME" --repo "$REPO"
printf '%s' "$keyAlias" | gh secret set ANDROID_KEY_ALIAS --env "$ENV_NAME" --repo "$REPO"

echo "Updated Production secrets on $REPO (passwords from key.properties, not printed)."
