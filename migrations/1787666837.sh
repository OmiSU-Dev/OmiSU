echo "Enable Dell XPS 13 sidecar speaker amplifiers"

if omisu-hw-dell-xps13-sidecar-amps; then
  source "$OMISU_PATH/install/hardware/dell-xps13-sidecar-amps.sh"
  omisu-state set reboot-required
fi
