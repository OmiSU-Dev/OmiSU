# OmiSu Shell: Bar, Plugins, and Idle

Read this before changing the status bar, notifications, shell plugins,
widgets, or idle/lock behavior.

The bar, notification daemon, settings panel, and assorted overlays all run
inside a single long-running Quickshell process (`omisu-shell`).

```
~/.config/omisu/shell.json             # User overrides: bar, plugins, idle
~/.config/omisu/plugins/<plugin-id>/   # User-owned shell plugins
$OMISU_PATH/config/omisu/shell.json  # Canonical defaults
```

The shell hot-reloads `shell.json` on save — no restart needed for layout
changes. `idle.screensaver` and `idle.lock` are seconds since user idle began.

**Commands:** `omisu restart shell`, `omisu refresh shell`

## Bar Layout

Use the `omisu bar` group to move and manage widgets:

```bash
omisu bar move omisu.clock --section right
```

For layout edits beyond what the commands cover, edit the bar configuration
in `~/.config/omisu/shell.json`; it hot-reloads on save.

## Customizing Built-In Plugins and Widgets

To customize a built-in bar widget, never edit `$OMISU_PATH/shell/plugins/`.
Clone it into the user plugin directory instead:

```bash
omisu plugin clone omisu.workspaces
# Edit ~/.config/omisu/plugins/<username>.workspaces/; saved changes reload automatically.
```

Cloning switches the bar to the cloned copy (e.g. `<username>.workspaces`),
which is yours to edit and survives updates.

Saving a file anywhere under `~/.config/omisu/plugins/` reloads plugin code
automatically. If a change somehow fails to apply, force a reload with
`omisu-shell shell rescanPlugins`.

## Idle and Lock

Set `idle.screensaver` and `idle.lock` in `~/.config/omisu/shell.json`,
in seconds since user idle began. Example: "lock after ten minutes" means
setting `idle.lock` to `600`.
