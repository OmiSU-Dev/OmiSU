echo "Install default coding agent mise wrappers"

if [[ ! -f $HOME/.local/state/omisu/preinstalls-removed ]]; then
  omisu-mise-install github:can1357/oh-my-pi omp
  omisu-mise-install npm:@xai-official/grok grok
  omisu-mise-install crush
elif [[ -f $HOME/.local/bin/omp ]] && grep -Eq 'mise use -g .*"oh-my-pi"' "$HOME/.local/bin/omp"; then
  rm -f "$HOME/.local/bin/omp"
fi
