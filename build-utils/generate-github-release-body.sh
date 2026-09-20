#!/usr/bin/env bash
# Markdown body for softprops/action-gh-release (shown in-app as release notes).
# Requires: full git history + tags on CI (checkout fetch-depth: 0).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FULL=$(grep '^version:' pubspec.yaml | head -1 | awk '{print $2}' | tr -d '\r')
SEMVER="${FULL%%+*}"
BUILD="${FULL#*+}"
if [ "$BUILD" = "$FULL" ]; then BUILD=""; fi
RELEASE_TAG="${NORDI_RELEASE_TAG:-v${SEMVER}-build${BUILD}}"

SHA="${GITHUB_SHA:-$(git rev-parse HEAD)}"
SHORT_SHA="${SHA:0:7}"
REPO="${GITHUB_REPOSITORY:-OmiSU-Dev/OmiSU}"

TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
PREV_REF="${NORDI_PREV_RELEASE_TAG:-}"

if [ -z "$PREV_REF" ] && command -v gh >/dev/null 2>&1 && [ -n "$TOKEN" ]; then
  PREV_REF=$(GH_TOKEN="$TOKEN" gh api "repos/${REPO}/releases/latest" --jq '.tag_name' 2>/dev/null || true)
fi

if [ -n "$PREV_REF" ] && ! git rev-parse "${PREV_REF}^{commit}" >/dev/null 2>&1; then
  git fetch --tags origin 2>/dev/null || true
fi

if [ -z "$PREV_REF" ] || ! git rev-parse "${PREV_REF}^{commit}" >/dev/null 2>&1; then
  if [ -n "$BUILD" ] && [ "$BUILD" -gt 0 ] 2>/dev/null; then
    PREV_CANDIDATE="v${SEMVER}-build$((BUILD - 1))"
    if git rev-parse "${PREV_CANDIDATE}^{commit}" >/dev/null 2>&1; then
      PREV_REF="$PREV_CANDIDATE"
    fi
  fi
fi

if [ -n "$PREV_REF" ] && ! git rev-parse "${PREV_REF}^{commit}" >/dev/null 2>&1; then
  echo "::warning::Previous release tag not found in git; changelog will use recent commits only."
  PREV_REF=""
fi

echo "# Nordi ${FULL}"
echo ""
echo "**Tag:** \`${RELEASE_TAG}\` · **Commit:** [\`${SHORT_SHA}\`](https://github.com/${REPO}/commit/${SHA})"
echo ""

HIGHLIGHTS_FILE="$ROOT/build-utils/release-highlights/v${SEMVER}-build${BUILD}.md"
if [ -n "$BUILD" ] && [ -f "$HIGHLIGHTS_FILE" ]; then
  cat "$HIGHLIGHTS_FILE"
  echo ""
fi

echo "## What's changed"
echo ""

if [ -n "$PREV_REF" ]; then
  COUNT=$(git rev-list --count "${PREV_REF}..HEAD" 2>/dev/null || echo 0)
  if [ "${COUNT:-0}" -gt 0 ]; then
    git log "${PREV_REF}..HEAD" --pretty=format:'- %s (`%h`)' --no-merges
  else
    echo "- $(git log -1 --pretty=format:'%s (`%h`)')"
  fi
else
  git log -20 --pretty=format:'- %s (`%h`)' --no-merges
fi

echo ""
echo ""

if [ -n "$PREV_REF" ]; then
  STAT=$(git diff --stat "${PREV_REF}..HEAD" 2>/dev/null | tail -n 1 || true)
  if [ -n "$STAT" ] && [ "$STAT" != " 0 files changed" ]; then
    echo "### Files touched"
    echo ""
    echo '```'
    git diff --stat "${PREV_REF}..HEAD" | head -n 40
    echo '```'
    echo ""
  fi

  if ! git diff --quiet "${PREV_REF}..HEAD" -- pubspec.yaml pubspec.lock 2>/dev/null; then
    echo "### Dependencies (pubspec)"
    echo ""
    echo '```'
    git diff "${PREV_REF}..HEAD" -- pubspec.yaml pubspec.lock | head -n 100
    echo '```'
    echo ""
  fi
fi

echo "---"
echo "_Generated for **${FULL}** when this release was published._"
