echo "Install hey (hey-cli) via mise wrapper"

if [[ ! -f $HOME/.local/state/omisu/preinstalls-removed ]]; then
  omisu-mise-install github:basecamp/hey-cli hey
fi
