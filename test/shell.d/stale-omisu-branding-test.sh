#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

# Fail if user-facing paths still reference the old Omarchy brand name.
allowlist=(
  'scripts/rebrand-to-omisu.sh'
  'scripts/import-omisu-themes.sh'
  'test/shell.d/stale-omisu-branding-test.sh'
  'OMISU-ARCH-FORK-PLAN.md'
)

while IFS= read -r hit; do
  [[ -z "$hit" ]] && continue
  file="${hit%%:*}"
  skip=0
  for allowed in "${allowlist[@]}"; do
    [[ "$file" == *"$allowed"* ]] && skip=1 && break
  done
  (( skip )) && continue
  fail "stale omarchy branding reference" "$hit"
done < <(rg -n '\bomarchy\b' "$ROOT" --glob '!.git' 2>/dev/null || true)

pass "no stale omarchy branding strings outside allowlist"
