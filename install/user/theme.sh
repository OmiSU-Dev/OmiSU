# Setup user theme folder and apply the OmiSu flat theme engine default.
mkdir -p ~/.config/omisu/themes ~/.config/omisu/branding

if [[ ! -f $HOME/.config/omisu/branding/about.txt ]] && [[ -f $OMISU_PATH/logo.txt ]]; then
  cp -f "$OMISU_PATH/logo.txt" "$HOME/.config/omisu/branding/about.txt"
fi

if [[ ! -s $HOME/.local/share/omisu/active-theme ]]; then
  if [[ ${OMISU_SETUP_CONTEXT:-runtime} != "runtime" ]]; then
    OMISU_THEME_HEADLESS=1 omisu-theme phoenix
    rm -f ~/.config/chromium/SingletonLock
  else
    omisu-theme phoenix
  fi
fi
