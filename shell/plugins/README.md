# First-party plugins

These plugins ship with OmiSu and are discovered by the shell at startup.
They use the same `manifest.json` contract as third-party plugins; the
only difference is that the shell flags them with `__isFirstParty: true`.
First-party non-bar plugins are enabled unless listed in `disabledPlugins[]`;
`omisu.bar` is the default bar option and becomes inactive only while another
`kind: "bar"` plugin is selected. Services and keep-loaded panels are mounted
at startup; other panels, overlays, and menus are loaded on demand.

User-installed plugins live alongside these conceptually but on disk under
`~/.config/omisu/plugins/<plugin-id>/` rather than in this directory.

| Plugin        | id                        | kinds                   | entry point                           |
|---------------|---------------------------|-------------------------|---------------------------------------|
| Bar           | `omisu.bar`             | `bar`                   | `bar/Bar.qml`                         |
| Image picker  | `omisu.image-picker`    | `overlay`               | `image-picker/ImagePicker.qml`        |
| Emojis        | `omisu.emojis`          | `overlay`               | `emojis/Emojis.qml`                   |
| Clipboard mgr | `omisu.clipboard`       | `overlay`               | `clipboard/Clipboard.qml`             |
| Reminders     | `omisu.reminders`       | `overlay`               | `reminders/ReminderFlow.qml`          |
| OmiSu menu  | `omisu.menu`            | `menu`, `bar-widget`    | `menu/Menu.qml`, `menu/BarWidget.qml` |
| Notifications | `omisu.notifications`   | `service`               | `notifications/Service.qml`           |
| Audio         | `omisu.audio`           | `bar-widget`            | `panels/audio/Panel.qml`              |
| Bluetooth     | `omisu.bluetooth`       | `bar-widget`            | `panels/bluetooth/Panel.qml`          |
| Clock         | `omisu.clock`           | `bar-widget`            | `panels/clock/BarWidget.qml`          |
| Monitor       | `omisu.monitor`         | `bar-widget`            | `panels/monitor/Panel.qml`            |
| Network       | `omisu.network`         | `bar-widget`            | `panels/network/Panel.qml`            |
| Power         | `omisu.power`           | `bar-widget`            | `panels/power/Panel.qml`              |
| Tailscale     | `omisu.tailscale`       | `bar-widget`            | `panels/tailscale/Panel.qml`          |
| Agents   | `omisu.agents`     | `bar-widget`            | `agents/Panel.qml`               |
| Weather       | `omisu.weather`         | `bar-widget`            | `panels/weather/BarWidget.qml`        |
| Media         | `omisu.media`           | `service`, `bar-widget` | `services/media/Service.qml`, `services/media/BarWidget.qml` |
| Battery       | `omisu.battery`         | `service`               | `services/battery/Service.qml`        |
| Idle          | `omisu.idle`            | `service`               | `services/idle/Service.qml`           |
| Night light   | `omisu.nightlight`      | `service`               | `services/nightlight/Service.qml`     |
| Lock screen   | `omisu.lock`            | `service`               | `lock/Service.qml`                    |
| OSD           | `omisu.osd`             | `panel`                 | `osd/Osd.qml`                         |
| Polkit agent  | `omisu.polkit`          | `service`               | `polkit/PolkitAgent.qml`              |

First-party bar-only widgets also carry manifests next to their QML files,
e.g. `bar/widgets/Workspaces.manifest.json`. Rich popup widgets live in their
own plugin directories, each with its own `manifest.json`.

## Bar

The built-in status bar and default full-bar option. Layout lives in the
top-level `bar:` subtree of `~/.config/omisu/shell.json` (with the shell
providing [`config/omisu/shell.json`](../../config/omisu/shell.json) when
the user has no file). See [`bar/README.md`](bar/README.md) for the widget catalogue
and customization schema.

## Image picker

Fullscreen image-grid selector overlay. Used by `omisu-menu-images`
(wallpaper picker) and `omisu-theme-switcher` (theme picker) and any
other caller that wants to present a directory of images with previews.

Two ways to drive it:

- Shell-level summon: `omisu-shell shell summon omisu.image-picker '<jsonPayload>'`.
  The payload can carry `imageDirs`, `imageRows`, `selectedImage`,
  `selectionFile`, `doneFile`, `showLabels`, `filterable`. Best for
  in-shell callers that already speak JSON.
- Direct IPC target: `omisu-shell image-selector open <imageDirs> <imageRowsB64> <selectedImage> <selectionFile> <doneFile> <showLabels> <filterable>`.
  Positional args; `imageRowsB64` is base64-encoded so embedded newlines /
  tabs survive the bash argv handoff. This is what `omisu-menu-images`
  uses. Colors come from the central shell theme singleton; there is no
  per-call override surface.

The selection round-trip remains file-based: callers create a
`selection_file` and `done_file` (both `mktemp`), pass the paths, and
poll `done_file` for existence. The plugin writes the chosen path into
`selection_file` and touches `done_file` when it's done. `cancel` IPC
clears it without writing a selection.

The plugin has `keepLoaded: true` so the layer-shell window survives
between summons within a single shell session.

## Lock screen

Session-lock surface using Quickshell's native `WlSessionLock` and two
separate PAM services: `omisu-lock-password` for password auth and,
only when fingerprints are enrolled, `omisu-lock-fingerprint` for
fingerprint auth. It mirrors the previous lock screen field dimensions,
colors, blurred wallpaper, placeholder, and Hyprland-driven corners.

## Polkit agent

Theme-aware authentication dialog for privileged actions. It uses
Quickshell's native `Quickshell.Services.Polkit.PolkitAgent` backend and
runs inside the long-lived `omisu-shell` process, replacing the old
`polkit-gnome-authentication-agent-1` autostart.

## OmiSu menu

Quickshell-powered OmiSu command menu.
The menu UI lives in `menu/Menu.qml` as a first-party `menu` plugin and is
summoned through the shell (`omisu-shell shell summon omisu.menu ...`),
so it shares the long-running `omisu-shell` process instead of starting a
second Quickshell instance.

The menu definition lives outside the shell host code:

- defaults: `default/omisu/omisu-menu.jsonc`
- user extensions: `~/.config/omisu/extensions/omisu-menu.jsonc`

The shell parses both JSONC files at startup (with `watchChanges: true`
so edits take effect without a restart), evaluates `when:` / `checked:`
bash expressions in a single batched subprocess, and executes the
selected `action:` string directly via `Quickshell.execDetached`. The
long-running shell process keeps the parsed menu in memory, so the
keybind → IPC → visible path costs ~30ms cold.

## Coming soon

- `omisu.theme-switcher` — folds theme switching into the shell.
