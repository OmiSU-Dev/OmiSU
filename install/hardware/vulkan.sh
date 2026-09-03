# Install Vulkan drivers matching detected GPU hardware
# (NVIDIA Vulkan is handled by nvidia.sh via nvidia-utils)

declare -A VULKAN_DRIVERS=(
  [Intel]=vulkan-intel
  [AMD]=vulkan-radeon
  [Apple]=vulkan-asahi
)

PACKAGES=()

for vendor in "${!VULKAN_DRIVERS[@]}"; do
  if lspci | grep -iE "(VGA|Display).*$vendor" > /dev/null; then
    pkg="${VULKAN_DRIVERS[$vendor]}"
    # Lite USB mirrors only ship listed packages. Requesting one that is
    # not in the sync DB (`target not found`) aborts Configuring system.
    if pacman -Si "$pkg" &>/dev/null; then
      PACKAGES+=("$pkg")
    else
      echo "Skipping $pkg ($vendor GPU detected; package not in repositories)"
    fi
  fi
done

if (( ${#PACKAGES[@]} > 0 )); then
  omisu-pkg-add "${PACKAGES[@]}"
fi
