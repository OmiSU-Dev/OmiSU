#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

open_and_close() {
  local name="$1" plugin="$2" namespace="$3" payload="${4:-}"

  if [[ -n $payload ]]; then
    omisu-shell shell summon "$plugin" "$payload" >/dev/null
  else
    omisu-shell shell summon "$plugin" >/dev/null
  fi

  wait_until "$name opens" 15 layer_present "$namespace"
  sleep 1
  screenshot "success-$name-open"

  omisu-shell shell hide "$plugin" >/dev/null
  wait_until "$name closes" 15 layer_absent "$namespace"
}

# Search and select an emoji. The host harness separately proves the shortcut
# with a QMP hardware key chord, while this test focuses on UI behavior.
omisu-shell shell summon omisu.emojis >/dev/null
wait_until "emoji picker opens" 15 layer_present "omisu-emojis"
wtype "rocket"
sleep 1
screenshot "success-emoji-picker-search"
wtype -k Return
wait_until "emoji picker selection closes" 15 layer_absent "omisu-emojis"

# Seed two clipboard entries, search for the older one, and copy it back out.
clipboard_token="OmiSu acceptance clipboard $(date +%s)"
printf '%s' "$clipboard_token" | wl-copy
wait_until "clipboard history captures test text" 15 grep -Fq "$clipboard_token" "$HOME/.local/state/omisu/clipboard-history.json"
printf '%s' "clipboard decoy" | wl-copy
sleep 1

omisu-shell shell summon omisu.clipboard >/dev/null
wait_until "clipboard opens" 15 layer_present "omisu-clipboard"
wtype "$clipboard_token"
wait_until "clipboard search finds test text" 15 screen_contains "OmiSu acceptance clipboard"
screenshot "success-clipboard-search"
wtype -M shift -k Return -m shift
wait_until "clipboard selection closes" 15 layer_absent "omisu-clipboard"
wait_until "clipboard selection restores test text" 15 bash -c '[[ $(wl-paste --no-newline) == "$1" ]]' _ "$clipboard_token"

# Exercise the system branch without invoking any destructive action.
omisu-shell shell summon omisu.menu '{"menu":"system"}' >/dev/null
wait_until "system menu opens" 15 layer_present "omisu-menu"
wait_until "system menu content is visible" 15 screen_contains "Shutdown"
screenshot "success-system-menu"
wtype -k Escape
wait_until "system menu closes" 15 layer_absent "omisu-menu"

# Preview both visual selectors and cancel without changing user state. These
# cover thumbnail generation, the image-grid overlay, and current selection.
launch_app "omisu-theme-bg-switcher"
wait_until "background selector opens" 30 layer_present "omisu-image-selector"
sleep 1
screenshot "success-background-selector"
wtype -k Escape
wait_until "background selector closes" 15 layer_absent "omisu-image-selector"

launch_app "omisu-theme-switcher"
wait_until "theme selector opens" 30 layer_present "omisu-image-selector"
sleep 1
screenshot "success-theme-selector"
wtype -k Escape
wait_until "theme selector closes" 15 layer_absent "omisu-image-selector"

# Walk the reminder flow through each input screen, but dismiss before it
# schedules a real timer in the test user's session.
omisu-shell shell summon omisu.reminders >/dev/null
wait_until "reminder flow opens" 15 layer_present "omisu-reminders"
screenshot "success-reminder-01-minutes-prompt"
wtype "5"
sleep 1
screenshot "success-reminder-02-minutes-entered"
wtype -k Return
wait_until "reminder message prompt opens" 15 screen_contains "Reminder message"
screenshot "success-reminder-03-message-prompt"
wtype -k Escape
wait_until "reminder flow closes" 15 layer_absent "omisu-reminders"

# Render a real shell notification and clear it through the notification IPC.
omisu-shell notifications dismissAll >/dev/null
omisu-notification-send "Acceptance notification" "Shell notification rendering" --expire-time=15000
wait_until "notification popup opens" 15 layer_present "omisu-notifications"
wait_until "notification content is visible" 15 screen_contains "Acceptance notification"
screenshot "success-notification-popup"
omisu-shell notifications dismissAll >/dev/null
wait_until "notification popup closes" 15 layer_absent "omisu-notifications"

# The menu's Apps submenu does the full launcher loop: open, search by
# typing, launch the top hit.
if window_present "(?i)omawrite" >/dev/null 2>&1; then
  fail "app launch test starts with no Omawrite window" "an Omawrite window is already open"
fi

omisu-menu summon apps >/dev/null
wait_until "apps menu opens" 15 layer_present "omisu-menu"
sleep 1
screenshot "success-apps-menu-open"

wtype "omawrite"
sleep 1
screenshot "success-apps-menu-search"
wtype -k Return

wait_until "apps menu launches the top search hit" 60 window_present "(?i)omawrite"
wait_until "apps menu closes after launching" 15 layer_absent "omisu-menu"

close_windows "(?i)omawrite"
wait_until "Omawrite window closes" 30 window_absent "(?i)omawrite"
