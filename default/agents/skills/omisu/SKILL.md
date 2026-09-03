---
name: omisu
description: >
  REQUIRED for end-user customization of Linux desktop, window manager, or system config.
  Use when editing ~/.config/hypr/, ~/.config/omisu/,
  ~/.config/alacritty/, ~/.config/foot/, ~/.config/kitty/, or ~/.config/ghostty/.
  Triggers: Hyprland, window rules, animations, keybindings, monitors, gaps, borders,
  blur, opacity, omisu-shell, bar, terminal config, themes, background,
  night light, idle, lock screen, screenshots, reminders, layer rules, workspace
  settings, display config, and user-facing omisu commands. Excludes OmiSu
  source development through `omisu dev link` workflows.
---

# OmiSu Skill

Manage [OmiSu](https://omisu.org/) Linux systems - a beautiful, modern, opinionated Arch Linux distribution with Hyprland.

This skill is for end-user customization on installed systems.
It is not for contributing to OmiSu source code.

## When This Skill MUST Be Used

**ALWAYS invoke this skill for end-user requests involving ANY of these:**

- Editing ANY file in `~/.config/hypr/` (window rules, animations, keybindings, monitors, etc.)
- Editing `~/.config/omisu/shell.json` (status bar layout, widgets)
- Editing terminal configs (alacritty, foot, kitty, ghostty)
- Editing ANY file in `~/.config/omisu/`
- Window behavior, animations, opacity, blur, gaps, borders
- Layer rules, workspace settings, display/monitor configuration
- Themes, backgrounds, fonts, appearance changes
- User-facing `omisu` commands (`omisu theme ...`, `omisu refresh ...`, `omisu restart ...`, etc.)
- Screenshots, screen recording, reminders, night light, idle behavior, lock screen

**If you're about to edit a config file in ~/.config/ on this system, STOP and use this skill first.**

**Do NOT use this skill for OmiSu development tasks** (editing the OmiSu source tree, creating migrations, or running `omisu dev ...` workflows).

## Topic Guides

Deeper instructions for common areas live next to this file. Read the
matching guide before starting:

- [`hyprland.md`](hyprland.md) - keybindings, monitors, window rules, and other Hyprland config
- [`plugins.md`](plugins.md) - the OmiSu shell: bar layout, widgets, plugins, idle behavior
- [`theming.md`](theming.md) - themes, backgrounds, and fonts
- [`hooks.md`](hooks.md) - automation hooks that run on system events
- [`capture.md`](capture.md) - screenshots, screen recordings, OCR text capture, and file sharing
- [`contributing.md`](contributing.md) - reporting OmiSu bugs and submitting fixes upstream

## Critical Safety Rules

For privileged commands, follow the Privilege Escalation rules below: `sudo` when a terminal is available for the password prompt, `pkexec` when it is not. Do not wrap commands that already manage privilege elevation themselves.

**For end-user customization tasks, NEVER modify anything in `/usr/share/omisu/`** - but READING is safe and encouraged.

This directory is owned by the omisu package. Any local changes will be
overwritten on the next `omisu update`.

```
/usr/share/omisu/     # READ-ONLY - NEVER EDIT (reading is OK)
├── bin/                    # Command source (packaged binaries are on PATH)
├── config/                 # Default config templates
├── themes/                 # Stock themes
├── default/                # System defaults
├── shell/                  # OmiSu shell source and defaults
├── migrations/             # Update migrations
└── install/                # Installation scripts
```

**Reading `/usr/share/omisu/` is SAFE and useful** - do it freely to:
- Understand how omisu commands work: `omisu theme set --help` or `cat $(which omisu-theme-set)`
- See default configs before customizing: `cat "$OMISU_PATH/config/omisu/shell.json"`
- Check stock theme files to copy for customization
- Reference default hyprland settings: `cat /usr/share/omisu/default/hypr/*`

**Always use these safe locations instead:**
- `~/.config/` - User configuration (safe to edit)
- `~/.config/omisu/themes/<custom-name>/` - Custom themes
- `~/.config/omisu/hooks/` - Custom automation hooks

If the request is to develop OmiSu itself, this skill is out of scope. Follow repository development instructions instead of this skill.

## Privilege Escalation

For an interactive script or command run in a visible terminal, use `sudo` for
privileged work. OmiSu may grant passwordless `sudo` access to particular
commands, and the terminal is the appropriate place to request a password
when one is needed.

Use `pkexec` only when the caller cannot interact with a terminal or cannot
enter a password there, such as a command launched by an agent or a graphical
background process. Do not replace `sudo` with `pkexec` merely because a
command changes system state.

## System Architecture

OmiSu is built on:

| Component | Purpose | Config Location |
|-----------|---------|-----------------|
| **Arch Linux** | Base OS | `/etc/`, `~/.config/` |
| **Hyprland** | Wayland compositor/WM | `~/.config/hypr/` |
| **OmiSu shell** | Status bar + notifications (Quickshell) | `~/.config/omisu/shell.json` |
| **Launcher/menus** | Quickshell menu | `~/.config/omisu/extensions/omisu-menu.jsonc` |
| **Alacritty/Foot/Kitty/Ghostty** | Terminals | `~/.config/<terminal>/` |
| **OmiSu OSD** | On-screen display | Quickshell plugin |

## Command Discovery

OmiSu ships a single `omisu` CLI that dispatches to all `omisu-*` binaries via `omisu <group> <action>`. Always prefer this form — it is self-documenting and stable. The underlying `omisu-*` binaries still exist on `PATH` and remain safe to read for source.

```bash
# List every documented command and its summary (--all includes hidden commands)
omisu commands

# Show the commands inside a group
omisu theme --help
omisu refresh --help
omisu restart --help

# Show help for a specific command (does not execute it)
omisu theme set --help

# Machine-readable listing (binary, route, summary, args, aliases)
omisu commands --json

# Read a command's source to understand it
cat $(which omisu-theme-set)
```

### Command Groups

Run `omisu --help` for the full list. The most common groups:

| Group | Purpose | Example |
|-------|---------|---------|
| `omisu refresh` | Reset config to defaults (backs up first) | `omisu refresh shell` |
| `omisu restart` | Restart a service/app | `omisu restart shell` |
| `omisu toggle` | Toggle feature on/off | `omisu toggle nightlight` |
| `omisu theme` | Theme management | `omisu theme set <name>` |
| `omisu bar` | Bar layout and widgets | `omisu bar move omisu.clock --section right` |
| `omisu plugin` | Manage/clone shell plugins | `omisu plugin clone omisu.clock` |
| `omisu hook` | Install automation hooks | `omisu hook install theme-set <script>` |
| `omisu install` | Install optional software / packages | `omisu install docker dbs` |
| `omisu launch` | Launch apps | `omisu launch browser` |
| `omisu capture` | Screenshots and recordings | `omisu capture screenshot` |
| `omisu reminder` | Desktop notification reminders | `omisu reminder 15 "Pickup Jack"` |
| `omisu pkg` | Package management | `omisu pkg add <pkg>` |
| `omisu setup` | Interactive setup wizards | `omisu setup security fingerprint` |
| `omisu update` | System updates | `omisu update` |

## Configuration Locations

Hyprland config lives in `~/.config/hypr/` — see [`hyprland.md`](hyprland.md).
The OmiSu shell (bar, notifications, plugins, idle) is configured in
`~/.config/omisu/shell.json` — see [`plugins.md`](plugins.md).

### Terminals

```
~/.config/alacritty/alacritty.toml
~/.config/foot/foot.ini
~/.config/kitty/kitty.conf
~/.config/ghostty/config
```

**Command:** `omisu restart terminal`

### Other Configs

| App | Location |
|-----|----------|
| btop | `~/.config/btop/btop.conf` |
| fastfetch | `/etc/fastfetch/config.jsonc` default; `~/.config/fastfetch/config.jsonc` user override |
| lazygit | `~/.config/lazygit/config.yml` |
| starship | `~/.config/starship.toml` |
| git | `~/.config/git/config` |

## Safe Customization Patterns

### Edit User Config Directly

For simple changes, edit files in `~/.config/`:

```bash
# 1. Read current config
cat ~/.config/hypr/bindings.lua

# 2. Backup before changes
cp ~/.config/hypr/bindings.lua ~/.config/hypr/bindings.lua.bak.$(date +%s)

# 3. Make changes with Edit tool

# 4. Apply changes
# - Hyprland: auto-reloads on save, but MUST validate with `hyprctl reload` and `hyprctl configerrors`
# - OmiSu shell: shell.json and user plugin code under ~/.config/omisu/plugins/ hot-reload on save
# - Menus/launcher: ~/.config/omisu/extensions/omisu-menu.jsonc hot-reloads on save
# - Terminals: apply with `omisu restart terminal` (reloads running terminals; foot picks changes up in new windows)
```

### Reset to Defaults -- ALWAYS SEEK USER CONFIRMATION BEFORE RUNNING

When customizations go wrong:

```bash
# Reset specific config (creates backup automatically)
omisu refresh shell
omisu refresh hyprland

# The refresh command:
# 1. Backs up current config with timestamp
# 2. Copies default from $OMISU_PATH/config/
# 3. Restarts the component where the refresh needs it (e.g. `refresh shell`)
```

## System Commands

```bash
omisu update                  # Full system update
omisu version                 # Show OmiSu version
omisu debug --no-sudo --print # Debug info (ALWAYS use these flags)
omisu system lock             # Lock screen
omisu system shutdown         # Shutdown
omisu system reboot           # Reboot
```

**IMPORTANT:** Always run `omisu debug` with `--no-sudo --print` flags to avoid interactive sudo prompts that will hang the terminal.

## Troubleshooting

```bash
# Get debug information (ALWAYS use these flags to avoid interactive prompts)
omisu debug --no-sudo --print

# Reset specific config to defaults
omisu refresh <app>

# Refresh specific config file
# config-file path is relative to ~/.config/
# eg. `omisu refresh config hypr/hyprland.lua` will refresh ~/.config/hypr/hyprland.lua
omisu refresh config <config-file>

# Full reinstall of configs (nuclear option)
omisu reinstall
```

## Decision Framework

When user requests system changes:

1. **Is it a stock omisu command?** Use it directly
2. **Is it a config edit?** Edit in `~/.config/`, never `/usr/share/omisu/`
3. **Is it a theme customization?** Follow [`theming.md`](theming.md); create a NEW custom theme directory
4. **Is it automation?** Follow [`hooks.md`](hooks.md); use `omisu hook install` and the hook `.d` directories
5. **Is it a package install?** Use `omisu pkg add <pkgs...>` (or `omisu pkg aur add <pkgs...>` for AUR-only packages)
6. **Is it built-in shell/plugin code?** Follow [`plugins.md`](plugins.md); clone it with `omisu plugin clone`, never edit the packaged copy
7. **Unsure if command exists?** Run `omisu commands` (or `omisu <group> --help` for one group)

### Reminder Requests

When the user asks to set a reminder, use `omisu reminder <minutes> [message]` directly. Convert natural language durations to minutes and title-case short reminder labels when appropriate.

```bash
omisu reminder 15 "Pickup Jack"
omisu reminder 60 "Check laundry"
omisu reminder show
omisu reminder clear
```

## Out of Scope

This skill intentionally does not cover OmiSu source development. Do not use this skill for:
- Editing files in `/usr/share/omisu/` (`bin/`, `config/`, `default/`, `shell/`, `themes/`, `migrations/`, etc.)
- Creating or editing migrations
- Running `omisu dev ...` commands

## Example Requests

- "Change my theme to catppuccin" -> `omisu theme set catppuccin`
- "Add a keybinding for Super+E to open file manager" -> Check existing bindings first, call `hl.unbind` if needed, then `o.bind` in `~/.config/hypr/bindings.lua`
- "Configure my external monitor" -> Edit `~/.config/hypr/monitors.lua`
- "Make the window gaps smaller" -> Edit `~/.config/hypr/looknfeel.lua`
- "Turn on night light" -> `omisu toggle nightlight` (for time-based schedules, edit `~/.config/hypr/hyprsunset.conf` profiles, then `omisu restart hyprsunset`)
- "Set a reminder to pickup jack in 15 minutes" -> `omisu reminder 15 "Pickup Jack"`
- "Show my reminders" -> `omisu reminder show`
- "Clear all reminders" -> `omisu reminder clear`
- "Customize the catppuccin theme colors" -> Overlay: put an edited `colors.toml` in `~/.config/omisu/themes/catppuccin/`, then re-apply the theme (see `theming.md`)
- "Run a script every time I change themes" -> Install it with `omisu hook install theme-set <script>`
- "Change how workspace labels are rendered" -> Clone `omisu.workspaces`, which switches the bar to `<username>.workspaces`, then edit the clone
- "Lock after ten minutes" -> Set `idle.lock` to `600` in `~/.config/omisu/shell.json`
- "Reset shell/bar to defaults" -> `omisu refresh shell`
- "Record my screen" -> `omisu screenrecord --fullscreen`, then `omisu screenrecord --stop-recording` (see `capture.md`)
- "Report this bug to OmiSu" -> Gather diagnostics and a capture of the problem, then file it (see `contributing.md`)
