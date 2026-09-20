#!/usr/bin/env bash
# Fails CI if release-notes.md does not match the build being published.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

NOTES_FILE="${1:-release-notes.md}"
FULL=$(grep '^version:' pubspec.yaml | head -1 | awk '{print $2}' | tr -d '\r')
SEMVER="${FULL%%+*}"
BUILD="${FULL#*+}"
TAG="v${SEMVER}-build${BUILD}"

if [ ! -s "$NOTES_FILE" ]; then
  echo "::error::${NOTES_FILE} is missing or empty."
  exit 1
fi

BODY=$(cat "$NOTES_FILE")

if ! grep -q "$FULL" "$NOTES_FILE"; then
  echo "::error::Release notes must include pubspec version ${FULL}."
  exit 1
fi

if ! grep -q "$TAG" "$NOTES_FILE"; then
  echo "::error::Release notes must include release tag ${TAG}."
  exit 1
fi

if grep -qE 'Automated release from|Bump `version` in `pubspec`|\$1' "$NOTES_FILE"; then
  echo "::error::Release notes look like the old static template or broken markdown (\\\$1)."
  exit 1
fi

if ! grep -q "## What's changed" "$NOTES_FILE"; then
  echo "::error::Release notes must contain a 'What's changed' section."
  exit 1
fi

if ! grep -qE '^- ' "$NOTES_FILE"; then
  echo "::error::Release notes must list at least one commit bullet under What's changed."
  exit 1
fi

echo "Release notes OK for ${FULL} (${TAG}, $(wc -c < "$NOTES_FILE") bytes)"
