#!/bin/bash

source "$(dirname "$0")/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
mkdir -p "$mock_bin" "$test_tmp/home/.config/chromium" "$test_tmp/home/.local/share/omisu"

cat >"$mock_bin/omisu-theme" <<'SH'
#!/bin/bash
printf '%s\n' "$*" >>"$OMISU_TEST_THEME_CALLS"
SH
chmod +x "$mock_bin/omisu-theme"

calls="$test_tmp/theme-calls"
touch "$test_tmp/home/.config/chromium/SingletonLock"
HOME="$test_tmp/home" PATH="$mock_bin:$PATH" OMISU_PATH="$ROOT" OMISU_TEST_THEME_CALLS="$calls" \
  bash "$ROOT/install/user/theme.sh"
grep -Fx 'phoenix' "$calls" >/dev/null || fail "user theme setup seeds Phoenix when no theme exists"
[[ -f $test_tmp/home/.config/chromium/SingletonLock ]] || fail "runtime user theme setup preserves Chromium's singleton lock"

: >"$calls"
mkdir -p "$test_tmp/home/.local/share/omisu"
printf 'Solitude\n' >"$test_tmp/home/.local/share/omisu/active-theme"
HOME="$test_tmp/home" PATH="$mock_bin:$PATH" OMISU_PATH="$ROOT" OMISU_TEST_THEME_CALLS="$calls" \
  bash "$ROOT/install/user/theme.sh"
[[ ! -s $calls ]] || fail "user theme setup preserves an existing theme"

pass "user theme setup only seeds the default theme once"
