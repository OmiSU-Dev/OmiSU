#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

# vulkan.sh always runs during Configuring system. On AMD (or AMD iGPU +
# NVIDIA dGPU) it calls omisu-pkg-add vulkan-radeon. Lite ISOs install from
# the USB offline mirror; if the package is not listed, pacman reports
# "target not found: vulkan-radeon" and the whole install dies.

for list in omisu-other-lite.packages omisu-other-lite-nvidia.packages; do
  grep -qxF vulkan-radeon "$ROOT/install/$list" ||
    fail "$list ships vulkan-radeon for offline AMD / hybrid installs" \
      "$(grep -n vulkan "$ROOT/install/$list" || true)"
  pass "$list ships vulkan-radeon for offline AMD / hybrid installs"
done

# Drivers that are not in the sync DB must be skipped, not requested.
# vulkan-asahi is the same failure mode on machines the Lite USB never covered.
test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT
mock_bin="$test_tmp/bin"
mkdir -p "$mock_bin"

cat >"$mock_bin/lspci" <<'SH'
#!/bin/bash
printf '%s\n' '01:00.0 VGA compatible controller: Advanced Micro Devices, Inc. [AMD/ATI] Device'
printf '%s\n' '01:00.1 Display controller: NVIDIA Corporation Device'
SH

cat >"$mock_bin/pacman" <<'SH'
#!/bin/bash
if [[ $1 == -Si && $2 == vulkan-intel ]]; then
  exit 0
fi
exit 1
SH

pkg_log="$test_tmp/pkg-add.log"
: >"$pkg_log"
cat >"$mock_bin/omisu-pkg-add" <<SH
#!/bin/bash
printf '%s\n' "\$@" >>"$pkg_log"
exit 0
SH
chmod +x "$mock_bin"/*

PATH="$mock_bin:$PATH" bash -eE -c 'source "$1"' bash "$ROOT/install/hardware/vulkan.sh"

if grep -qxF vulkan-radeon "$pkg_log"; then
  fail "vulkan.sh does not request a driver missing from the sync DB" \
    "requested: $(tr '\n' ' ' <"$pkg_log")"
fi
pass "vulkan.sh does not request a driver missing from the sync DB"

[[ ! -s $pkg_log ]] ||
  fail "no vulkan packages are requested when none are in the sync DB" \
    "requested: $(tr '\n' ' ' <"$pkg_log")"
pass "no vulkan packages are requested when none are in the sync DB"
