echo "Install ori (OpenRouter's agent harness) via mise wrapper"

if [[ ! -f $HOME/.local/state/omisu/preinstalls-removed ]]; then
  omisu-mise-install github:OpenRouterLabs/ori-releases ori
fi
