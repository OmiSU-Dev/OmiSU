# Update localdb so locate can find the installed system files immediately.
# Lite omits plocate; fd/ripgrep replace locate there.
command -v updatedb >/dev/null || exit 0
updatedb
