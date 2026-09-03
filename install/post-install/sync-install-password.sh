# Ensure the install user's password matches the ISO configurator passphrase.
# LUKS uses the plaintext passphrase; archinstall sets enc_password hashes
# separately — re-apply with chpasswd so sudo matches disk unlock.
set -euo pipefail

passfile=/etc/omisu/install.passphrase
[[ -f $passfile ]] || exit 0

user=${OMISU_INSTALL_USER:?OMISU_INSTALL_USER required}
pass=$(<"$passfile")

printf '%s:%s\n' "$user" "$pass" | chpasswd
printf '%s:%s\n' root "$pass" | chpasswd
command -v faillock >/dev/null && faillock --reset || true
shred -u "$passfile" 2>/dev/null || rm -f "$passfile"
