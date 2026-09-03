echo "Switch Brave Origin from the beta to the stable release"

if omisu-pkg-present brave-origin-beta-bin; then
  default_browser=$(xdg-settings get default-web-browser 2>/dev/null || true)

  omisu-pkg-aur-add brave-origin-bin
  omisu-pkg-drop brave-origin-beta-bin

  mkdir -p ~/.config
  cp -f "$OMISU_PATH/config/chromium-flags.conf" ~/.config/brave-origin-flags.conf
  rm -f ~/.config/brave-origin-beta-flags.conf

  if [[ $default_browser == "brave-origin-beta.desktop" ]]; then
    omisu-default-browser brave-origin
  fi
fi
