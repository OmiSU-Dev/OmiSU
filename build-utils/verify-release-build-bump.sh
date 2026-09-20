#!/usr/bin/env bash
# Ensures pubspec +build is strictly greater than the latest published Nordi APK.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FULL=$(grep '^version:' pubspec.yaml | head -1 | awk '{print $2}' | tr -d '\r')
BUILD="${FULL#*+}"
if [ "$BUILD" = "$FULL" ] || [ -z "$BUILD" ]; then
  echo "::error::pubspec version must include +build (e.g. 0.12.1+130). Got: $FULL"
  exit 1
fi

REPO="${GITHUB_REPOSITORY:-OmiSU-Dev/OmiSU}"
LAST_BUILD=0

if command -v gh >/dev/null 2>&1 && [ -n "${GH_TOKEN:-}" ]; then
  ASSET_NAME=$(gh api "repos/${REPO}/releases/latest" --jq '.assets[].name' 2>/dev/null | grep 'nordi-gamesir-arm64-v8a-' | head -1 || true)
  if [ -n "$ASSET_NAME" ]; then
    PARSED=$(echo "$ASSET_NAME" | sed -n 's/.*+\([0-9][0-9]*\)\.apk$/\1/p')
    if [ -n "$PARSED" ]; then
      LAST_BUILD="$PARSED"
    fi
  fi
fi

if [ "$BUILD" -le "$LAST_BUILD" ]; then
  echo "::error::pubspec build +$BUILD must be greater than latest release build +$LAST_BUILD"
  exit 1
fi

echo "Build number +$BUILD is greater than latest published +$LAST_BUILD"
