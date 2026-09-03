echo "Install oh-my-pi (omp) via mise wrapper"

if [[ ! -f $HOME/.local/state/omisu/preinstalls-removed ]]; then
  omisu-mise-install github:can1357/oh-my-pi omp
fi
