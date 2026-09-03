# OmiSu Lite — package alternatives

> **Goal:** Same OmiSu soul (terminal-first, Phoenix theme, Quickshell bar, `gum` menus, storm screensaver) with a smaller install and ISO than Omarchy.
>
> **Sources:** `install/omisu-base.packages`, `install/omisu-other.packages` (Omarchy-parity lists today).
>
> **Outputs:** `install/omisu-lite.packages`, `install/omisu-other-lite.packages`
>
> **Legend:** `KEEP` · `DROP` · `REPLACE` · `PROFILE` (install on demand via `omisu-pkg-add` / menu / hardware script)

---

## Design rules (lighter but still OmiSu)

1. **One heavy stack per role** — one browser, one editor, one volume tool, one search tool.
2. **Theme is code, not GNOME** — flat `omisu-theme`, Plymouth/SDDM branding, `starship` + `fastfetch`; skip Yaru/GTK2 theme packs.
3. **Hardware is detected, not bundled** — ISO mirror ships laptop-core drivers; NVIDIA/Mac/Dell/Framework land via `install/hardware/*` profiles.
4. **Cool stays in the shell** — keep `btop`, `fzf`, `eza`, `bat`, `ripgrep`, `zoxide`, `starship`; drop duplicate TUIs.
5. **Keep `mise-bin` for AI** — agent shims, `omisu-heal`, and dev-env menus depend on it; Docker stays opt-in (no `ufw-docker` on every machine).

**Rough savings vs current lists:** ~40% smaller installed footprint, ~35–45% smaller ISO offline mirror (mostly from `omisu-other` hardware/GPU bundles).

---

## `omisu-base.packages` — line by line

| Package | Action | Lite alternative | Why (OmiSu-themed) |
|---------|--------|------------------|---------------------|
| `aether` | DROP | `omisu-screensaver` + `omisu-branding-screensaver` | Rain-writes the OmiSu logo; no web-app screensaver |
| `alsa-utils` | KEEP | — | Audio CLI; small, useful |
| `asdcontrol` | PROFILE | `omisu-pkg-add asdcontrol` | AirPods/device control; niche |
| `avahi` | KEEP | — | `.local` hostnames; tiny |
| `bash-completion` | KEEP | — | Shell polish |
| `bat` | KEEP | — | Syntax-highlighted cat; fits terminal aesthetic |
| `bluez` | KEEP | — | Bluetooth stack |
| `bluez-tools` | DROP | `bluetoothctl` (in `bluez`) | Duplicate BT CLI |
| `bluez-utils` | KEEP | — | `bluetoothctl`, adapters |
| `bolt` | KEEP | — | Thunderbolt; laptops |
| `brightnessctl` | KEEP | — | Backlight keys |
| `btop` | KEEP | — | Panel-friendly system monitor |
| `chromium` | KEEP | — | **Default browser**; one Electron-class app max |
| `clang` | DROP | `base-devel` / install when building | ~300 MB compiler tree |
| `cliamp` | DROP | `playerctl` + Quickshell media widget | Terminal amp; shell already plays media |
| `cups` | PROFILE | `omisu-install-printing` | Printing stack |
| `cups-browsed` | PROFILE | ↑ same profile | Network printer discovery |
| `cups-filters` | PROFILE | ↑ same profile | Filter chain |
| `cups-pdf` | PROFILE | ↑ same profile | Virtual PDF printer |
| `ddcutil` | KEEP | — | External monitor control |
| `dosfstools` | KEEP | — | USB/EFI partitions |
| `dotnet-runtime` | PROFILE | `omisu-install-dev-env dotnet` | Dev-only runtime |
| `dua-cli` | DROP | `btop` + `dust` on demand | Duplicate disk TUIs |
| `exfatprogs` | KEEP | — | USB/exFAT |
| `expac` | KEEP | — | Tiny; pacman queries |
| `eza` | KEEP | — | Modern `ls`; matches starship/fzf vibe |
| `fakeroot` | KEEP | — | Needed for `checkupdates` / builds |
| `fastfetch` | KEEP | — | About screen + Phoenix branding |
| `fcitx5` | PROFILE | `omisu-install-input-cjk` | CJK input; English default |
| `fcitx5-gtk` | PROFILE | ↑ same profile | GTK IM module |
| `fcitx5-qt` | PROFILE | ↑ same profile | Qt IM module |
| `fd` | KEEP | — | Fast find |
| `ffmpegthumbnailer` | DROP | Thumbnails on demand | Pulls ffmpeg for little gain |
| `fontconfig` | KEEP | — | Required |
| `foot` | KEEP | — | **Default terminal**; fast Wayland term |
| `fzf` | KEEP | — | Fuzzy finder for menus/scripts |
| `git` | KEEP | — | Core tool |
| `gnome-keyring` | KEEP | — | Secrets/SSH agent |
| `gnome-themes-extra` | DROP | `omisu-theme <name>` | GTK2 Adwaita legacy; you own theming |
| `grim` | KEEP | — | Screenshots (Hypr-native) |
| `gpu-screen-recorder` | DROP | `wf-recorder` (profile) | Heavy; `grim`+`slurp` for stills |
| `gum` | KEEP | — | OmiSu menus and wizards |
| `gvfs-mtp` | KEEP | — | Phone MTP |
| `gvfs-nfs` | PROFILE | `omisu-pkg-add gvfs-nfs` | NFS mounts; niche |
| `gvfs-smb` | KEEP | — | SMB shares |
| `hyprland` | KEEP | — | Compositor |
| `hyprland-guiutils` | DROP | `hyprctl` + keybinds | GUI helpers; optional polish |
| `hyprland-preview-share-picker` | KEEP | — | `xdph.conf` screen-share picker |
| `hyprpicker` | KEEP | — | Color picker + capture freeze |
| `hyprsunset` | KEEP | — | Night light toggle + bar plugin |
| `imagemagick` | KEEP | — | `omisu-transcode` picture paths |
| `inetutils` | DROP | `iputils` (in `base`) | Legacy `telnet`/`ftp` tools |
| `inotify-tools` | KEEP | — | File watch scripts |
| `inxi` | KEEP | — | `omisu-debug` / hardware info |
| `networkmanager` | KEEP | — | Wi-Fi |
| `jq` | KEEP | — | JSON everywhere in OmiSu scripts |
| `kernel-modules-hook` | PROFILE | NVIDIA/hardware profiles | Only for DKMS stacks |
| `lazygit` | PROFILE | `omisu-pkg-add lazygit` | Nice TUI; not day-one |
| `less` | KEEP | — | Pager |
| `libsecret` | KEEP | — | Keyring dep |
| `libvips` | PROFILE | Install with app that needs it | Image pipeline |
| `libyaml` | KEEP | — | Small; config parsing |
| `llvm` | DROP | Install with `clang` profile | Huge |
| `lua51` | DROP | Lua 5.4 when needed | Legacy |
| `luarocks` | DROP | ↑ | Lua package manager |
| `man-db` | KEEP | — | Man pages |
| `mise-bin` | KEEP | — | Powers agent shims (`mise.sh`), `omisu-heal`, and dev-env installs |
| `mpv` | DROP | **Chromium** for video | Avoids large ffmpeg closure |
| `mpv-mpris` | DROP | ↑ | MPRIS without mpv |
| `noto-fonts` | KEEP | — | UI font baseline |
| `noto-fonts-cjk` | PROFILE | `omisu-install-font` CJK pack | **~150–200 MB** |
| `noto-fonts-emoji` | PROFILE | Optional emoji pack | Color emoji |
| `nss-mdns` | KEEP | — | `.local` resolution |
| `nvim` | KEEP | — | **Lite editor** (minimal config in skel) |
| `obsidian` | KEEP | — | Notes on `Super+Shift+O`; OmiSu theme sync |
| `omisu-nvim` | DROP | `nvim` + thin `config/nvim` in skel | LazyVim bundle **~100+ MB** |
| `pacman-contrib` | KEEP | — | `checkupdates` |
| `pamixer` | DROP | `wpctl` (WirePlumber) | Duplicate volume CLI |
| `plocate` | DROP | `fd` + `ripgrep` | Two search systems |
| `plymouth` | KEEP | — | Boot splash (OmiSu Plymouth theme) |
| `power-profiles-daemon` | KEEP | — | Laptop power modes |
| `python-gobject` | KEEP | — | Small; GTK/Python hooks |
| `python-poetry-core` | PROFILE | `omisu-install-dev-env python` | Poetry projects only |
| `ttfx` | DROP | `omisu-theme` font tokens | Theme engine covers typography |
| `qemu-user-static-binfmt` | PROFILE | Cross-arch builds only | Niche |
| `qrencode` | KEEP | — | QR for Wi-Fi/share; tiny |
| `qt6-imageformats` | KEEP | — | Qt image plugins for shell/apps |
| `quickshell` | KEEP | — | OmiSu bar |
| `ripgrep` | KEEP | — | Fast grep |
| `ruby` | PROFILE | `omisu-install-dev-env ruby` | Dev runtime |
| `tensaku` | DROP | `fzf` + dictionary web | Translation lookup |
| `sddm` | KEEP | — | Login greeter (OmiSu SDDM theme) |
| `slurp` | KEEP | — | Region select for `grim` |
| `socat` | KEEP | — | Script glue |
| `starship` | KEEP | — | Prompt matches theme colors |
| `system-config-printer` | PROFILE | `omisu-install-printing` | GTK printer UI |
| `tesseract` | KEEP | — | `omisu-capture-text` OCR |
| `tesseract-data-eng` | KEEP | — | English OCR data |
| `tldr` | DROP | `man` + `omisu` help | Redundant with docs |
| `tree-sitter-cli` | DROP | ISO build-only | Not for end users |
| `tmux` | KEEP | — | `Super+Alt+Return` + keybinds menu |
| `ttf-ia-writer` | DROP | `ttf-jetbrains-mono-nerd-basic` | One mono aesthetic |
| `ttf-jetbrains-mono-nerd-basic` | KEEP | — | **OmiSu terminal font** |
| `tzupdate` | KEEP | — | Timezone sync |
| `udiskie` | KEEP | — | Auto-mount USB |
| `ufw` | KEEP | — | Firewall |
| `ufw-docker` | DROP | `ufw` only; Docker profile separate | **Pulls full Docker stack** |
| `unzip` | KEEP | — | Archives |
| `usage` | DROP | `btop` / `fastfetch` | Duplicate vitals |
| `uwsm` | KEEP | — | Session manager |
| `whois` | PROFILE | `omisu-pkg-add whois` | Rare |
| `wireless-regdb` | KEEP | — | Legal Wi-Fi channels |
| `wireplumber` | KEEP | — | PipeWire session |
| `wl-clipboard` | KEEP | — | Wayland clipboard |
| `wtype` | KEEP | — | Type into windows (automation) |
| `woff2-font-awesome` | KEEP | — | Icon font for web/shell |
| `xdg-desktop-portal-gtk` | KEEP | — | File picker portal |
| `xdg-desktop-portal-hyprland` | KEEP | — | Hyprland portal |
| `xdg-terminal-exec` | KEEP | — | Default terminal routing |
| `yaru-icon-theme` | DROP | `hicolor` + app icons; optional Papirus profile | Full GNOME icon set |
| `yay` | DROP | `omisu-pkg-add` | OmiSu-native package helper |
| `yt-dlp` | PROFILE | `omisu-install-app yt-dlp` | Heavy ffmpeg deps |
| `zbar` | KEEP | — | QR scan; small |
| `zoxide` | KEEP | — | Smart `cd`; terminal QoL |

---

## `omisu-other.packages` — ISO mirror (hardware & drivers)

| Package | Action | Lite alternative | Why |
|---------|--------|------------------|-----|
| `autoconf-archive` | DROP | Pull when building AUR | Build helper |
| `asusctl` | PROFILE | `install/hardware/asus-rog.sh` | ASUS ROG only |
| `base` | KEEP | — | Installer target |
| `base-devel` | KEEP | — | Builds / headers |
| `broadcom-wl` | DROP | `install/hardware/fix-bcm43xx.sh` | Stock `linux` module; profile install for BCM43xx |
| `btrfs-progs` | KEEP | — | Btrfs installs |
| `dkms` | KEEP | — | Dynamic kernel modules |
| `egl-wayland` | KEEP | — | NVIDIA/EGL on Wayland |
| `gst-plugin-pipewire` | KEEP | — | PipeWire GStreamer |
| `gtk4-layer-shell` | KEEP | — | Layer-shell widgets |
| `libpulse` | KEEP | — | Pulse compat layer |
| `intel-ipu7-camera` | PROFILE | `install/hardware/intel/ipu7-camera.sh` | Specific Intel cameras |
| `intel-lpmd` | PROFILE | Intel laptop profile | Low-power daemon |
| `intel-media-driver` | KEEP | — | **Intel iGPU video** (common laptop) |
| `libva-intel-driver` | KEEP | — | VA-API Intel |
| `libva-nvidia-driver` | PROFILE | NVIDIA profile | Only with NVIDIA |
| `limine` | KEEP | — | Bootloader |
| `limine-mkinitcpio-hook` | KEEP | — | Initramfs → Limine |
| `limine-snapper-sync` | KEEP | — | Snapper boot entries |
| `linux` | DROP | `archinstall.packages` + target install | Live ISO boots stock `linux`; don't mirror twice |
| `linux-firmware` | KEEP | — | Wi-Fi/GPU firmware |
| `linux-headers` | KEEP | — | DKMS builds |
| `linux-ptl` | PROFILE | `install/hardware/intel/ptl-kernel.sh` | Intel PTL niche |
| `linux-ptl-headers` | PROFILE | ↑ | PTL headers |
| `macbook12-spi-driver-dkms` | PROFILE | Mac T2 profile | MacBook only |
| `nvidia-580xx-dkms` | PROFILE | `install/hardware/nvidia.sh` | NVIDIA proprietary |
| `nvidia-dkms` | PROFILE | ↑ | NVIDIA |
| `nvidia-open-dkms` | PROFILE | ↑ | NVIDIA open kernel module |
| `nvidia-580xx-utils` | PROFILE | ↑ | Userspace |
| `nvidia-utils` | PROFILE | ↑ | Userspace |
| `lib32-nvidia-580xx-utils` | PROFILE | Gaming/multilib profile | 32-bit games |
| `lib32-nvidia-utils` | PROFILE | ↑ | 32-bit games |
| `pipewire` | KEEP | — | Audio server |
| `pipewire-alsa` | KEEP | — | ALSA compat |
| `pipewire-jack` | PROFILE | Pro-audio profile | JACK compat |
| `pipewire-pulse` | KEEP | — | PulseAudio compat |
| `qt6-wayland` | KEEP | — | Qt on Wayland |
| `snapper` | KEEP | — | Snapshots / `omisu-update` |
| `sof-firmware` | KEEP | — | Intel SOF audio |
| `thermald` | KEEP | — | Intel thermal |
| `webp-pixbuf-loader` | KEEP | — | WebP thumbnails |
| `yay-debug` | DROP | — | Debug symbols; never ship |
| `tuxedo-drivers-nocompatcheck-dkms` | PROFILE | Tuxedo laptops | Vendor DKMS |
| `yt6801-dkms` | PROFILE | `fix-yt6801-ethernet-adapter.sh` | Specific NIC |
| `zram-generator` | KEEP | — | Compressed swap |
| `libvpl` | PROFILE | Intel encode profile | Video encoding |
| `vpl-gpu-rt` | PROFILE | ↑ | Intel encode runtime |
| `vulkan-intel` | KEEP | — | **Intel Vulkan** (laptop default) |
| `vulkan-radeon` | KEEP | — | **AMD Vulkan** (iGPU / hybrid with NVIDIA) |
| `vulkan-asahi` | PROFILE | Apple Silicon (future) | Asahi |
| `linux-firmware-marvell` | PROFILE | Surface profile | Surface Wi-Fi |
| `dell-xps-touchpad-haptics` | PROFILE | `install/hardware/dell-xps-*` | Dell XPS |
| `dell-xps13-sidecar-amps` | PROFILE | ↑ | Dell XPS audio |
| `lsp-plugins-lv2` | PROFILE | `install/hardware/speaker-tuning.sh` | Speaker EQ |
| `apple-bcm-firmware` | PROFILE | Mac T2 profile | T2 Wi-Fi firmware |
| `apple-t2-audio-config` | PROFILE | ↑ | T2 audio |
| `linux-t2` | PROFILE | `install/hardware/apple/fix-t2.sh` | **~200 MB**; Mac T2 post-install, not default ISO |
| `linux-t2-headers` | PROFILE | ↑ | T2 DKMS |
| `t2fanrd` | PROFILE | ↑ | T2 fan daemon |
| `qmk-hid` | PROFILE | `install/hardware/framework16.sh` | Framework 16 |

---

## OmiSu Lite “cool stack” (what you ship instead of Omarchy bloat)

| Role | Omarchy-style (heavy) | OmiSu Lite (themed, lighter) |
|------|------------------------|------------------------------|
| Brand / boot | Omarchy Plymouth + Yaru icons | **Phoenix `omisu-theme`** + OmiSu Plymouth/SDDM |
| About / identity | fastfetch + Omarchy art | **fastfetch** + OmiSu sheen animation |
| Screensaver | aether web app | **`omisu-screensaver`** storm logo |
| Bar | Quickshell plugin bar | **Quickshell** (keep) |
| Prompt | starship | **starship** (theme-synced) |
| System monitor | btop + usage + dua | **btop** only |
| Search | plocate + fd + fzf | **fd + fzf + ripgrep** |
| Terminal | foot + extras | **foot** |
| Editor | omisu-nvim (LazyVim) | **nvim** minimal |
| Browser | chromium + obsidian | **chromium** + **obsidian** |
| Music | cliamp | **playerctl** + bar widget |
| Screenshot | grim + gpu-screen-recorder | **grim + slurp** |
| Screen record | gpu-screen-recorder | **`wf-recorder`** (profile) |
| Notes | obsidian (`Super+Shift+O`) | **obsidian** |
| Fonts | Noto + CJK + emoji + iA Writer + Yaru | **Noto + JetBrains Nerd** |
| Packages | yay + mise + docker | **`omisu-pkg-add`** + **`mise-bin`** (agents/dev); Docker opt-in |
| Printing | full CUPS GUI | **profile** |
| GPU drivers | all NVIDIA + all Vulkan | **Intel laptop core** + profiles |

---

## Profile commands (suggested `omisu-install-*` targets)

| Profile | Packages / script | When |
|---------|-------------------|------|
| `omisu-install-printing` | cups*, system-config-printer | User has a printer |
| `omisu-install-input-cjk` | fcitx5* | CJK input needed |
| `omisu-install-font-cjk` | noto-fonts-cjk | CJK glyphs |
| `omisu-install-media` | mpv, yt-dlp, wf-recorder | Local video / download |
| `omisu-install-editor-lazyvim` | omisu-nvim | Power Neovim users |
| Notes hotkey (`Super+Shift+O`) | obsidian | **obsidian** |
| `omisu-install-docker` | docker, ufw-docker | Containers |
| `omisu-install-gpu-nvidia` | nvidia-*, libva-nvidia, vulkan (pick one) | NVIDIA hardware |
| `omisu-install-edition-mac-t2` | linux-t2, apple-*, t2fanrd | Intel Mac |
| Hardware quirks | existing `install/hardware/*.sh` | Detect at install |

---

## File index

| File | Purpose |
|------|---------|
| `omisu-base.packages` | Current full desktop (Omarchy parity) |
| `omisu-other.packages` | Shared laptop ISO mirror (Standard + Lite) |
| **`omisu-lite.packages`** | Recommended lite desktop list |
| **`omisu-other-lite-nvidia.packages`** | Alias of `omisu-other.packages` (Lite docs) |
| **`omisu-lite/`** | Separate Lite + NVIDIA ISO build project |
| **`omisu-lite-alternatives.md`** | This document |

To build a lite ISO, point the ISO builder at `omisu-lite.packages` + `omisu-other-lite.packages` instead of the full lists.
