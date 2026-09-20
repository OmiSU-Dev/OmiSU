#!/bin/bash
set -e

# Nord N30 / GameSir curated Android build (Nordi tree).
# Usage:
#   NORDI_ROM_ROOT=/storage/emulated/0/ROMS ./build-utils/build-gamesir-android.sh
#
# Optional: ENV_FILE=.env for API keys; same signing vars as build-android.sh.

export NORDI_ROM_ROOT="${NORDI_ROM_ROOT:-/storage/emulated/0/ROMS}"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

EXTRA_DEFINES=(
  "--dart-define=NORDI_ROM_ROOT=${NORDI_ROM_ROOT}"
  "--dart-define=OMISU_DEVICE_PROFILE=nord_n30"
)

ENV_FILE="${ENV_FILE:-.env}"
if [ -f "$ENV_FILE" ]; then
  EXTRA_DEFINES+=("--dart-define-from-file=$ENV_FILE")
fi

echo "Building Nordi (GameSir / Nord N30) APK..."
echo "  ROM root: $NORDI_ROM_ROOT"

FVM_FLUTTER="$PROJECT_ROOT/.fvm/flutter_sdk/bin/flutter"
if ! command -v flutter &> /dev/null; then
  if [ -x "$FVM_FLUTTER" ]; then
    export PATH="$PROJECT_ROOT/.fvm/flutter_sdk/bin:$PATH"
    echo "Using Nordi FVM Flutter: $FVM_FLUTTER"
  else
    echo "Error: Flutter not found in PATH and no $FVM_FLUTTER"
    exit 1
  fi
fi

if [ -n "$KEYSTORE_PASSWORD" ] && [ -n "$KEY_PASSWORD" ] && [ -n "$KEY_ALIAS" ] && [ -n "$KEYSTORE_PATH" ]; then
  {
    printf 'storePassword=%s\n' "$KEYSTORE_PASSWORD"
    printf 'keyPassword=%s\n' "$KEY_PASSWORD"
    printf 'keyAlias=%s\n' "$KEY_ALIAS"
    printf 'storeFile=%s\n' "$KEYSTORE_PATH"
  } > android/key.properties
fi

flutter build apk --release --split-per-abi --no-tree-shake-icons \
  --flavor gamesir \
  --target-platform android-arm64,android-arm \
  "${EXTRA_DEFINES[@]}"

VERSION=$(grep 'version:' pubspec.yaml | head -1 | awk '{print $2}' | tr -d '\r')
mkdir -p "$PROJECT_ROOT/release"
APK_DIR="$PROJECT_ROOT/build/app/outputs/flutter-apk"

for ABI in arm64-v8a armeabi-v7a; do
  SRC="$APK_DIR/app-$ABI-gamesir-release.apk"
  DST="$PROJECT_ROOT/release/nordi-gamesir-$ABI-$VERSION.apk"
  if [ -f "$SRC" ]; then
    cp "$SRC" "$DST"
  else
    echo "Missing $SRC"
    exit 1
  fi
done

echo "Done: release/nordi-gamesir-*-$VERSION.apk"
