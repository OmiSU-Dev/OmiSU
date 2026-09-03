echo "Pack virtio-gpu drivers for QEMU/OVMF Plymouth at the LUKS prompt"

# Installed UKIs built before omisu_virtio_gpu.conf listed virtio_dma_buf
# often lack both modules; Plymouth then falls back to the text encrypt prompt.
# Rebuild after omisu-settings ships the drop-in and refresh plymouth defaults.

if [[ -f /usr/share/plymouth/plymouthd.defaults ]]; then
  sed -i 's/^Theme=.*/Theme=omisu/' /usr/share/plymouth/plymouthd.defaults
fi

if command -v plymouth-set-default-theme >/dev/null 2>&1; then
  plymouth-set-default-theme omisu 2>/dev/null || true
fi

omisu-cmd-present limine-mkinitcpio || exit 0

if ! grep -q 'virtio_gpu?' /etc/mkinitcpio.conf.d/omisu_virtio_gpu.conf 2>/dev/null; then
  exit 0
fi

sudo limine-mkinitcpio

echo "OmiSu: rebuilt the boot image with virtio-gpu Plymouth support."
