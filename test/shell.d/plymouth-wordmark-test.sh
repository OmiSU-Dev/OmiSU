#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

theme="$ROOT/default/plymouth"
script="$theme/omisu.script"

# Sine-byte wordmark frames replace the shredded terminal-block logo.png
# on the splash. Five letters × six swell steps.
missing=()
for letter in 0 1 2 3 4; do
  for step in 0 1 2 3 4 5; do
    f="$theme/wm_${letter}_${step}.png"
    [[ -f $f ]] || missing+=("wm_${letter}_${step}.png")
  done
done
(( ${#missing[@]} == 0 )) ||
  fail "Plymouth ships sine-byte wordmark frames" "missing: ${missing[*]}"
pass "Plymouth ships sine-byte wordmark frames"

grep -q 'wm_0_0.png' "$script" ||
  fail "omisu.script loads the sine-byte wordmark frames"
pass "omisu.script loads the sine-byte wordmark frames"

grep -q 'progress_glow.sprite.SetOpacity' "$script" ||
  fail "progress glow opacity is animated"
pass "progress glow opacity is animated"

grep -q 'rain.sprites' "$script" ||
  fail "storm rain sprites remain in the splash"
pass "storm rain sprites remain in the splash"

grep -q 'wave.sprites' "$script" ||
  fail "storm wave sprites remain in the splash"
pass "storm wave sprites remain in the splash"
