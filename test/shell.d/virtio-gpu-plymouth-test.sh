#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

# The installer live ISO packs every DRM driver (archiso kms, no autodetect),
# so the custom Plymouth splash works. The installed UKI uses autodetect+kms.
# On QEMU/OVMF the live session is usually already on built-in simpledrm, so
# virtio_gpu is never loaded and never packed. After reboot Plymouth has no
# DRM device and encrypt falls back to:
#   A password is required to access the root volume:
#
# Pack virtio_gpu optionally — same '?' suffix as apple-t2 — so mkinitcpio
# skips it on machines without the module and never hard-fails the UKI.
# Do not require simpledrm: it is built-in and a required MODULE aborts
# limine-update with a branding-only ESP.

conf="$ROOT/etc/mkinitcpio.conf.d/omisu_virtio_gpu.conf"

[[ -f $conf ]] || fail "virtio_gpu mkinitcpio drop-in exists" "missing $conf"
pass "virtio_gpu mkinitcpio drop-in exists"

grep -qE 'MODULES\+\=\(.*virtio_dma_buf\?' "$conf" ||
  fail "virtio_dma_buf is optional so virtio-gpu can load in the UKI" \
    "actual: $(<"$conf")"
pass "virtio_dma_buf is optional so virtio-gpu can load in the UKI"

grep -qE 'MODULES\+\=\(.*virtio_gpu\?' "$conf" ||
  fail "virtio_gpu is optional so a missing module cannot abort the UKI" \
    "actual: $(<"$conf")"
pass "virtio_gpu is optional so a missing module cannot abort the UKI"

if grep -qE 'MODULES\+\=\([^)]*[[:space:]]simpledrm[[:space:]]' "$conf" ||
  grep -qE 'MODULES\+\=\(simpledrm[[:space:]]' "$conf" ||
  grep -qE 'MODULES\+\=\([^)]*[[:space:]]simpledrm\)' "$conf" ||
  grep -qE 'MODULES\+\=\(simpledrm\)' "$conf"; then
  fail "drop-in does not require built-in simpledrm" "actual: $(<"$conf")"
fi
pass "drop-in does not require built-in simpledrm"

# plymouthd.defaults ships Theme=bgrt, which is not in the UKI. branding.sh
# must rewrite it so the daemon loads omisu instead of exiting.
grep -q "Theme=omisu" "$ROOT/install/config/branding.sh" ||
  fail "branding.sh points plymouthd.defaults at Theme=omisu"
pass "branding.sh points plymouthd.defaults at Theme=omisu"

grep -q "UseSimpledrm=true" "$ROOT/etc/plymouth/plymouthd.conf" ||
  fail "plymouthd.conf uses the firmware framebuffer when no GPU module binds"
pass "plymouthd.conf uses the firmware framebuffer when no GPU module binds"

grep -q "plymouthd.defaults" "$ROOT/bin/omisu-refresh-plymouth" ||
  fail "omisu-refresh-plymouth rewrites plymouthd.defaults Theme=omisu"
pass "omisu-refresh-plymouth rewrites plymouthd.defaults Theme=omisu"

grep -q 'limine-mkinitcpio' "$ROOT/bin/omisu-refresh-plymouth" ||
  fail "omisu-refresh-plymouth rebuilds UKI via limine-mkinitcpio"
pass "omisu-refresh-plymouth rebuilds UKI via limine-mkinitcpio"

grep -q 'plymouthd.defaults' "$ROOT/bin/omisu-plymouth-set" ||
  fail "omisu-plymouth-set rewrites plymouthd.defaults Theme=omisu"
pass "omisu-plymouth-set rewrites plymouthd.defaults Theme=omisu"

grep -q 'limine-mkinitcpio' "$ROOT/bin/omisu-plymouth-set" ||
  fail "omisu-plymouth-set rebuilds UKI via limine-mkinitcpio"
pass "omisu-plymouth-set rebuilds UKI via limine-mkinitcpio"

[[ -f "$ROOT/migrations/1788137200.sh" ]] ||
  fail "virtio/Plymouth UKI migration exists for upgrades"
pass "virtio/Plymouth UKI migration exists for upgrades"
