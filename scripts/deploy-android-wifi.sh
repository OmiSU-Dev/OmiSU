#!/usr/bin/env bash
# Nordi (Nord N30) — delegates to monorepo deploy script.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$ROOT/scripts/deploy-android-wifi.sh" --product nordi "$@"
