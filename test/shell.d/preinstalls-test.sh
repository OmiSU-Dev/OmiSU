#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
test_home="$test_tmp/home"
marker="$test_home/.local/state/omisu/preinstalls-removed"
pkg_log="$test_tmp/packages"
mkdir -p "$mock_bin" "$test_home/.local/state/omisu"

for command in omisu-webapp-remove-all omisu-tui-remove-all omisu-refresh-applications hyprctl; do
  printf '#!/bin/bash\nexit 0\n' >"$mock_bin/$command"
done

cat >"$mock_bin/gum" <<'SH'
#!/bin/bash
[[ $1 == confirm ]] && exit "${OMISU_TEST_CONFIRM:-0}"
exit 0
SH

cat >"$mock_bin/omisu-pkg-add" <<'SH'
#!/bin/bash
printf '%s\n' "$@" >"$OMISU_TEST_PKG_LOG"
exit "${OMISU_TEST_PKG_ADD_STATUS:-0}"
SH

cat >"$mock_bin/omisu-pkg-drop" <<'SH'
#!/bin/bash
printf '%s\n' "$@" >"$OMISU_TEST_PKG_LOG"
SH

chmod +x "$mock_bin"/*

export PATH="$mock_bin:$PATH"
export HOME="$test_home"
export OMISU_TEST_PKG_LOG="$pkg_log"

# Both scripts restore and remove the same set, and every package in it has to be
# one OmiSu actually ships, or Remove Preinstalls takes out an app the user
# chose from the menu and Install Preinstalls puts back one we retired.
mapfile -t shipped < <(sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$ROOT/install/omisu-base.packages")

"$ROOT/bin/omisu-install-preinstalls" >/dev/null
mapfile -t restored <"$pkg_log"

"$ROOT/bin/omisu-remove-preinstalls" >/dev/null
mapfile -t dropped <"$pkg_log"

[[ ${restored[*]} == "${dropped[*]}" ]] ||
  fail "Install and Remove Preinstalls cover the same packages" \
    "restored: ${restored[*]}
dropped:  ${dropped[*]}"
pass "Install and Remove Preinstalls cover the same packages"

for package in "${restored[@]}"; do
  printf '%s\n' "${shipped[@]}" | grep -qxF "$package" ||
    fail "every preinstall is shipped in omisu-base.packages" "$package is not shipped"
done
pass "every preinstall is shipped in omisu-base.packages"

for package in aether cliamp; do
  printf '%s\n' "${restored[@]}" | grep -qxF "$package" ||
    fail "preinstalls cover the debloated optional packages" "$package is missing"
done
pass "preinstalls cover the debloated optional packages"

# The bindings key off the marker, so clearing it before the packages land would
# point them at apps that never came back.
touch "$marker"
OMISU_TEST_PKG_ADD_STATUS=1 "$ROOT/bin/omisu-install-preinstalls" >/dev/null && status=0 || status=$?
(( status == 1 )) || fail "restore reports a failed package transaction" "exit status was $status"
[[ -f $marker ]] || fail "restore keeps the opt-out marker when packages fail to install"
pass "restore keeps the opt-out marker when packages fail to install"

"$ROOT/bin/omisu-install-preinstalls" >/dev/null
[[ ! -e $marker ]] || fail "restore clears the opt-out marker once the packages are back"
pass "restore clears the opt-out marker once the packages are back"

rm -f "$marker"
OMISU_TEST_CONFIRM=1 "$ROOT/bin/omisu-remove-preinstalls" >/dev/null
[[ ! -e $marker ]] || fail "declining Remove Preinstalls changes nothing"
pass "declining Remove Preinstalls changes nothing"

"$ROOT/bin/omisu-remove-preinstalls" >/dev/null
[[ -f $marker ]] || fail "Remove Preinstalls records the opt-out"
pass "Remove Preinstalls records the opt-out"
