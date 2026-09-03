# File layout

How `omisu/` is organized and where everything ends up on an installed
system.

## Mental model

Two Arch packages are built from this one repo (PKGBUILDs live in the
separate `omisu-pkgs` repository, under `pkgbuilds/`):

- **`omisu`** — runtime binaries (`bin/`, including `bin/omisu-dev-*`),
  install/finalize scripts (`install/`), migrations, themes, and the
  Quickshell desktop (`shell/`). Depends on `omisu-settings`.
- **`omisu-settings`** — everything that has to be on the target *before*
  the omisu package installs (specifically before `useradd -m` and the
  limine bootloader install): all `/etc/skel/**`, `/etc/` drop-ins,
  package-owned system files under `/usr/share` and `/usr/lib`, fonts,
  plymouth theme, sddm theme, branding, plus the limine/snapper configs
  (mkinitcpio hooks, limine-entry-tool drop-ins, snapper template, the
  `default/limine/` and `default/snapper/` trees, and the boot/snapshot
  story end-to-end). Also ships the three debug binaries
  (`omisu-debug`, `omisu-debug-idle`, `omisu-upload-log`) needed by
  the live ISO env.

Two other packages live in `omisu-pkgs` but stand alone:
`omisu-keyring` (GPG keys for pacman) and `omisu-nvim` (the Neovim
setup; independently seeds `/etc/skel`).

Some trees ship in neither package and exist only in the repo: `manual/`
(user manual chapters), `agents/skills/` (contributor task guides), `docs/`,
`test/`, and `plans/`.

Three layers populate `$HOME`:

1. **Seed** — `omisu-settings` ships static defaults to `/etc/skel/`.
   Arch's `useradd -m` copies that tree into a new user's `$HOME` at user
   creation. This is the only mechanism that touches a brand-new user's home
   for these files.
2. **Finalize** — `omisu-provision-user` (routed as `omisu finalize
   user`) runs once per user and handles the things `/etc/skel` can't do
   because they need `$HOME` expansion, the live `$OMISU_PATH`, or runtime
   detection of system state.
3. **Resync** — `omisu-reinstall-configs` is the explicit, destructive
   command for an existing user to clobber their configs back to shipped
   defaults.

`/etc/skel` only fires at user creation. Existing users picking up new
defaults must use the resync command.

Deferred-provisioning installs (`omisu-apply-system --defer-provisioning`)
create no user at all: the ISO leaves `/var/lib/omisu/provisioning/pending`
behind, which arms `omisu-provision-owner.service` (shipped from
`install/provisioning/`, alongside the factory-reset finish unit and
`setup-form.sh`). On first boot `bin/omisu-provision-owner` creates the
user on tty1 and runs the finalize step itself.

Current generated theme state lives under
`~/.local/state/omisu/current/`. Keep `~/.config/omisu/` for files a user
may intentionally version in a dotfile manager, such as user themes, hooks,
shell layout, plugins, and themed template overrides.

## Build-time map (repo → installed paths)

```
omisu/                            built into          installed at
─────────────────────────           ──────────────      ────────────────────────────────────

bin/omisu-*                  ──►  omisu             /usr/bin/omisu-*
                                                        (and symlinks in /usr/share/omisu/bin/)
bin/omisu-debug,
bin/omisu-debug-idle,
bin/omisu-upload-log         ──►  omisu-settings    /usr/bin/  (needed before omisu is installed)

default/libalpm/hooks/*.hook
                                ──►  omisu             /usr/share/libalpm/hooks/*.hook

install/**                     ──►  omisu             /usr/share/omisu/install/
migrations/**                  ──►  omisu             /usr/share/omisu/migrations/
themes/**                      ──►  omisu             /usr/share/omisu/themes/
shell/**                       ──►  omisu             /usr/share/omisu/shell/
version                        ──►  omisu             /usr/share/omisu/version
                                                        + /etc/skel/.local/state/omisu/migrations/*

config/**                      ──►  omisu-settings    /etc/skel/.config/**         (seeds new users)
                                                        /usr/share/omisu/config/** (resync source)
etc/fastfetch/config.jsonc     ──►  omisu-settings    /etc/fastfetch/config.jsonc

applications/*.desktop         ──►  omisu-settings    /etc/skel/.local/share/applications/
                                                        /usr/share/omisu/applications/
default/applications/battlenet.desktop
                                ──►  omisu-settings    /usr/share/omisu/default/applications/
                                                        (installer-only launcher template)
applications/icons/*           ──►  omisu-settings    /usr/share/icons/hicolor/{48,256,scalable}/apps/

etc/**                         ──►  omisu-settings    /etc/**           (drop-ins we own outright)
  ├─ mkinitcpio.conf.d/{omisu_hooks,thunderbolt_module}.conf
  ├─ limine-entry-tool.d/{omisu-defaults,omisu-uki}.conf
  ├─ NetworkManager/, sudoers.d/, sysctl.d/, tmpfiles.d/,
  │  profile.d/omisu.sh, …                            (a summary — `ls etc/` for the full ~17-entry tree)
  └─ security/faillock.conf, nsswitch.conf,
     cups/cups-browsed.conf, plymouth/plymouthd.conf    /usr/share/omisu/etc-overrides/
                                                          → /etc/* (post_install cp -f, see below)

default/limine/limine.conf     ──►  omisu-settings    /usr/share/omisu/default/limine/limine.conf
default/limine/default.conf    ──►  omisu-settings    /usr/share/omisu/default/limine/default.conf
                                                        (template; ISO substitutes @@CMDLINE@@ → /etc/default/limine)
default/snapper/root           ──►  omisu-settings    /etc/snapper/config-templates/omisu
                                                        (+ /usr/share/omisu/default/snapper/root)

default/**                     ──►  omisu-settings    /usr/share/omisu/default/
  ├─ bash/env-bootstrap                                 /usr/share/omisu/default/bash/env-bootstrap
  │                                                       (sourced by every shell/session entry point; see "Env bootstrap")
  ├─ bashrc                                             /usr/share/omisu/etc-overrides/dot.bashrc
  │                                                       → /etc/skel/.bashrc (post_install cp -f)
  ├─ hypr/toggles/*.lua (flags,
  │    single-window-aspect-ratio, window-no-gaps)      /etc/skel/.local/state/omisu/toggles/hypr/
  ├─ nautilus-python/extensions/*.py                    /etc/skel/.local/share/nautilus-python/extensions/
  ├─ tensaku/state.toml                                 /etc/skel/.local/state/tensaku/state.toml
  ├─ uwsm/env.d/10-omisu                              /usr/share/uwsm/env.d/
  ├─ environment.d/*.conf                               /usr/lib/environment.d/
  ├─ fontconfig/conf.avail/50-omisu.conf              /usr/share/fontconfig/conf.avail/
  │                                                       + symlink /etc/fonts/conf.d/50-omisu.conf
  ├─ xdg-terminal-exec/*.list                           /usr/share/xdg-terminal-exec/
  ├─ applications/mimeapps.list                         /usr/share/applications/mimeapps.list
  ├─ systemd/user/*.service                             /usr/lib/systemd/user/
  ├─ systemd/user/app.slice.d/10-oomd.conf              /usr/lib/systemd/user/app.slice.d/
  ├─ systemd/system-sleep/{force-igpu,
  │    keyboard-backlight,unmount-fuse}                 /usr/lib/systemd/system-sleep/
  ├─ systemd/zram-generator.conf.d/90-omisu.conf      /usr/lib/systemd/zram-generator.conf.d/
  ├─ fonts/omisu/omisu.ttf                          /usr/share/fonts/omisu/
  ├─ sddm/omisu/                                      /usr/share/sddm/themes/omisu/
  ├─ sddm/hyprland.lua                                  /usr/share/sddm/hyprland.lua
  ├─ wayland-sessions/omisu.desktop                   /usr/local/share/wayland-sessions/
  └─ plymouth/                                          /usr/share/plymouth/themes/omisu/

logo.{txt,svg}, icon.{txt,png}  ──► omisu-settings    /usr/share/omisu/  (resync source)
                                                        /usr/share/pixmaps/omisu.png
                                                        /usr/share/icons/hicolor/256x256/apps/omisu.png
                                                        /etc/skel/.config/omisu/branding/{about,screensaver}.txt
```

### Why `etc-overrides/` exists

Some files under `/etc/` (`.bashrc` in `/etc/skel`, `nsswitch.conf`,
`security/faillock.conf`, `cups/cups-browsed.conf`, `plymouth/plymouthd.conf`)
are owned by upstream Arch packages, so we can't install over them via pacman
without a file conflict. Instead their sources (under `etc/` in the repo;
`.bashrc` from `default/bashrc`) ship at
`/usr/share/omisu/etc-overrides/` and the `omisu-settings` `post_install`
/ `post_upgrade` scriptlet `cp -f`'s them into place.

Tradeoff: user edits to those files get clobbered on every `omisu-settings`
upgrade. This is documented in the PKGBUILD.

## Env bootstrap (`default/bash/env-bootstrap`)

Single source of truth for `OMISU_PATH` and dev-link-aware `PATH`. It:

- Sources `/etc/omisu.conf` (written by `omisu-dev-link`, reset to the
  package path by `omisu-dev-unlink`) if present; otherwise forces
  `OMISU_PATH=/usr/share/omisu` so a stale inherited value can't survive
  an `omisu-dev-unlink`.
- Prepends `$OMISU_PATH/bin` to `PATH` **only when** `OMISU_PATH` is
  not `/usr/share/omisu`. On a production install the binaries are
  already on `PATH` as `/usr/bin/omisu-*` via the `omisu` package.
- Appends `~/.local/share/mise/shims` and `~/.local/bin` so login shells and
  the uwsm session find mise-managed tools — kept in sync with the PAM `PATH`
  line written by `install/config/ssh-command-path.sh`, which covers SSH
  commands that run no shell setup at all.

Sourced by every entry point that needs the env set:

```
/etc/profile.d/omisu.sh                      (system login shells)
/etc/skel/.bashrc                              (interactive shells)
/usr/share/uwsm/env.d/10-omisu               (Hyprland session via uwsm)
/usr/share/omisu/default/bash/envs           (SSH / non-login bash)
```

Idempotent — safe to source more than once in the same shell.

`PATH` covers everything the user runs, but not `sudo`, which resolves command
names against `secure_path` from `/etc/sudoers`. So `omisu-dev-link` also
writes `/etc/sudoers.d/omisu-dev-path`:

```
Defaults secure_path="<checkout>/bin:/usr/local/sbin:/usr/local/bin:/usr/bin"
```

Without it, `sudo omisu-*` fails for a command the package has not shipped
yet and silently runs the packaged copy of one it has. The drop-in is validated
with `visudo -c` before install and removed by `omisu-dev-unlink`; unlike
`/etc/omisu.conf`, it takes effect without a reboot.

## Runtime finalization (`omisu-provision-user`)

Runs once per user. It does **not** copy `~/.config/**`, `~/.bashrc`,
`flags.lua`, or the nautilus extensions — `/etc/skel` already seeded those.
It only does the things `/etc/skel` can't:

- Skill symlinks `~/.{agents,claude,codex,pi/agent}/skills/<name>` →
  `$OMISU_PATH/default/agents/skills/<name>`, looping over every skill
  directory there (currently `omisu` and `diagnose-crash`) so new skills
  need no edit. Symlinks (not copies) so `omisu dev link` against a dev
  checkout repoints them correctly.
- `xdg-user-dirs-update` (Templates/Public/Desktop folded back into `$HOME`)
  and `~/.config/gtk-3.0/bookmarks` (needs `$HOME` expansion).
- Hyprland's package-owned default input reads `XKBLAYOUT` / `XKBVARIANT`
  from `/etc/vconsole.conf`; no per-user Hyprland config rewrite is needed.
- `xdg-settings set default-web-browser chromium.desktop` and
  `xdg-mime default HEY.desktop x-scheme-handler/mailto` (XDG-aware paths).
- `omisu-refresh-applications` (composes generated `.desktop` launchers).
- Sources `install/user/all.sh` — theme, chromium, git, xcompose, mise,
  keyring, per-user hardware quirks (asus mic/mixer, framework f13 audio, …).
- On `--first-install`, marks every shipped user migration as already applied
  for the freshly-created user.

Idempotency marker: `~/.local/state/omisu/done/finalize-user`, managed
by `omisu-done`.

The ISO calls it as `omisu-provision-user --force --first-install` in the
target chroot as the install user, after `omisu-apply-system` has finished
the root-side work. `omisu-provision-owner` makes the same call (with
`OMISU_SETUP_CONTEXT=provision-owner`) when it creates the user during
deferred first-boot provisioning.

## Migrations (`omisu-migrate`)

See [`migrations.md`](../agents/skills/migrations.md) for the full migration model, authoring
guidelines, and troubleshooting notes.

OmiSu migrations live in `migrations/*.sh` and run per-user through
`omisu-migrate`. Completion state lives in
`~/.local/state/omisu/migrations/`, so every user gets a chance to run every
migration. Migrations run as the user; privileged work should invoke the
appropriate helper or privilege prompt. Migrations must be idempotent;
machine-wide repairs should no-op when another user already applied them.

Each graphical user has `omisu-migrate-notify.service`, started once per login
through `WantedBy=graphical-session.target` and ordered after that target so
notification actions can safely launch through UWSM. The `omisu-pkgs`
PKGBUILD has shipped `omisu-update-user-notify.service` as a symlink onto
it, so users enabled under the old unit name keep working before they reach
migration `1785095882`.
It runs `omisu-migrate-notify` as
that user, which checks `omisu-migrate --pending`. If this user has missing
migration state, it shows a notification that opens a terminal for
`omisu-migrate`. The notifier never runs migrations in the background.

Login is the only trigger. Nothing watches the packaged migration directory: a
watcher cannot tell a bypassed `pacman -Syu` from the package transaction inside
a normal `omisu update`, so it notified about migrations that `omisu-migrate`
was already applying in the visible update terminal.

`omisu-migrate` waits for any active pacman transaction to finish, then runs
pending migrations. It does not need `--force`; migrations happen when state
files are missing. `omisu update` runs `omisu-migrate` after the package
transaction in the already-visible update terminal, then runs
`omisu-hook post-update`.

## First-run (`omisu-provision-first-run`)

Runs once on first interactive login, after the user manager is live. It
first runs `omisu-provision-user || true` so finalize catches up if it
never ran, then handles the steps that need a running graphical session
and/or a working user systemd instance:

- `omisu-hook-install post-update` for the three shipped hooks
  (`install-voxtype.hook`, `setup-fingerprint.hook`, `setup-agent.hook`).
- `install/user/first-run/enable-user-units.sh` — daemon-reload, then
  `systemctl --user enable --now` the shipped user units (`bt-agent`,
  `omisu-sleep-lock`, `omisu-recover-internal-monitor`,
  `omisu-migrate-notify.service`, `omisu-fcitx5.service`,
  `omisu-crash-watch.service`) so they run in the first session too.
  Done here, not at finalize, because
  the user manager isn't reachable from the ISO chroot; `ConditionPath*`
  in the unit files keeps services inert when they don't apply.
- `install/user/first-run/gnome-theme.sh`,
  `install/user/first-run/gtk-primary-paste.sh` — GNOME/GTK settings that
  need the dconf daemon.
- `install/user/first-run/audio-tuning.sh` — apply speaker tuning.
- `install/user/first-run/welcome.sh` — keybindings toast that greets the
  first login and opens the cheatsheet when clicked. The caller runs
  `omisu-notification-wait` once before this and the Wi-Fi step, so both
  toasts land on a live notification server.
- `install/user/first-run/wifi.sh` — Wi-Fi/update toasts (waits detached on
  `nm-online` so the update prompt only lands once there is a connection).

The entire sequence has one idempotency marker:
`~/.local/state/omisu/done/first-run-user`, managed by `omisu-done`.
Completed users exit before any first-run step. On failure the marker is not
written and the sequence retries next login.

Completion markers live under `~/.local/state/omisu/done/`. Use
`omisu-done check <name>` to check one and `omisu-done mark <name>` to record it.
Use `omisu-done ensure <name>` as a conditional when the guarded work should
run only once; it records completion before returning success.
The Quattro upgrade completes graphical first-run for upgraded users and moves
the legacy finalization marker from `~/.local/state/omisu/` into `done/`.

## Root-side install orchestration

`omisu-apply-system` (root, in chroot) runs target-side setup at ISO
finalization. It sources:

- `install/config/all.sh` — theme links, lockout limits, lockscreen PAM,
  powerprofilesctl shebang fix, SSH command path and keepalive, docker setup,
  Snapper retention, locate index tuning, service enablement, firewall.
- `install/hardware/all.sh` via `omisu-apply-hardware` — vendor- and
  device-specific kernel modules, udev rules, microcode, wireless regdom,
  ASUS / Framework / Intel / Apple / Lenovo quirks.
- `install/login/all.sh` — SDDM theme/session config.
- `install/post-install/all.sh` — final pacman/udev/localdb passes.

Logging goes to `/var/log/omisu-install.log` via
`install/helpers/logging.sh`.

The package lists the ISO pacstraps live at `install/omisu-base.packages`
and `install/omisu-other.packages`; the ISO builder also reads them when
constructing its offline mirror.

## Explicit resync (`omisu-reinstall-configs`)

When an existing user wants to reset to shipped defaults:

```
~/  ←  cp -af /etc/skel/.
```

Replaying `/etc/skel` over `$HOME` is exactly what `useradd -m` does for a
brand-new user, so this one copy resyncs `.bashrc`, `.config/**`,
`.local/share/applications/`, the nautilus-python extensions, hypr toggles,
branding files, and the shipped migration markers in a single pass.

Then it runs `omisu-refresh-limine`, `omisu-refresh-plymouth`, and the
nvim refresh. Destructive: existing user files copied from `/etc/skel` are
clobbered without backup. Fastfetch is package-owned at
`/etc/fastfetch/config.jsonc`; delete `~/.config/fastfetch/config.jsonc` to
return to the packaged default.

## Quick reference: where does X live?

| Goal | Touch |
| --- | --- |
| Default file at `~/.config/foo/` | `config/foo/` |
| `/etc/` drop-in we own outright | `etc/` |
| `/etc/` file owned by an upstream package | `etc/` (see `etc/security/faillock.conf`), then add to `etc-overrides` in `omisu-settings` PKGBUILD + scriptlet |
| Package-owned system file (e.g. systemd user service in `/usr/lib`) | `default/`, then add the `install -Dm644` line in `omisu-settings` PKGBUILD |
| Per-user file that's static but lives outside `~/.config` | `default/`, then add `install -Dm644 ... $pkgdir/etc/skel/...` in `omisu-settings` PKGBUILD |
| Runtime tweak that needs `$HOME` or live system state | extend `omisu-provision-user`, or add a per-user leaf under `install/user/` and wire into `install/user/all.sh` |
| One-time root-side setup step | `install/config/*.sh` or `install/hardware/*.sh`, wire into `install/config/all.sh` or `install/hardware/all.sh` |
| One-time fix for existing installs | `migrations/<unix-timestamp>.sh` |
| Package-owned path something else may already write | Prefer a path nothing else writes, such as a vendor drop-in under `/usr/lib`. Otherwise the `--overwrite` entry in `bin/omisu-update-system-pkgs` has to ship a release before the file |
| User-facing `omisu-*` command | `bin/omisu-<group>-<verb>` — see `GROUP_DESCRIPTIONS` in `bin/omisu` |
| New stock theme | `themes/<name>/` (+ matching templates under `default/themed/` if they need theme colors) |
| User-installed theme | `~/.config/omisu/themes/<name>/` |
| Generated current theme/background state | `~/.local/state/omisu/current/` |
