# Shared OmiSu wordmark layout and install-screen copy.
#
# Body rows split after O+M+I (must match scripts/gen-logo.py logo_split_index()).
OMISU_TAGLINE='A minimal, malleable Omakase Hyprland brew'
OMISU_LOGO_SPLIT=37

# Print one logo.txt row: OMI in cyan-blue (36), SU in green (32).
# $1=line $2=0-based row index $3=CSI prefix $4=RESET suffix
omisu_print_logo_line() {
  local line="$1" row="${2:-1}" csi="${3-}" reset="${4-}"

  if (( row == 0 )); then
    printf '%b%s%b' "${csi}36m" "$line" "$reset"
    return
  fi

  printf '%b%s%b%s%b' \
    "${csi}36m" "${line:0:OMISU_LOGO_SPLIT}" \
    "${csi}32m" "${line:OMISU_LOGO_SPLIT}" \
    "$reset"
}

OMISU_INSTALL_TIPS=(
  "Super + Space opens the OmiSu menu for apps, settings, and more"
  "Super + K shows all the key bindings"
  "Super is the Windows or command key on your keyboard"
  "Super + Return opens a terminal; Super + Shift + Return opens Chromium"
  "Super + Shift + O opens Obsidian for notes"
  "Print takes a screenshot; Alt + Print records the screen"
  "Super + Ctrl + Print grabs text off the screen with OCR"
  "Switch themes from Style > Theme in the OmiSu menu"
  "Super + Ctrl + V opens the clipboard manager"
  "Super + 1 through 0 switches workspaces; add Shift to move the window"
  "Super + Print picks a color from anywhere on screen"
  "Keep the system fresh with Update in the OmiSu menu"
  "Double-click the menu bar to toggle transparency"
  "Super + T toggles a window between floating and tiled in Hyprland"
  "Super + F makes the focused window full screen; Super + W closes it"
  "Super + Arrow keys move focus between tiled windows"
  "Super + drag moves a window; Super + right-drag resizes it"
  "Super + J flips the split direction; Super + Shift + Backspace toggles gaps"
  "Super + mouse scroll switches workspaces on the focused monitor"
)
