# Reporting Issues and Shipping Fixes

Read this when the user wants to report an OmiSu bug, suggest a feature, or
contribute a fix from a bare-metal test install.

OmiSu lives at https://github.com/OmiSU-Dev/OmiSU (monorepo). Route requests
to the right place:

- **Verified bugs** -> GitHub issues on `OmiSU-Dev/OmiSU`
- **Feature ideas** -> GitHub issues with the `enhancement` label, or Discussions
  when enabled
- **Heal fixes from a test machine** -> PR to `main` (see below)

Upstream Omarchy remains at https://github.com/basecamp/omarchy — do not send
OmiSu fork fixes there.

## Bare-metal test -> GitHub ship protocol

Goal: prove fixes in a **fresh ISO reinstall**, not by porting `~/.config` or
installer-created user state.

### Repo layout

```text
OmiSU-Dev/OmiSU/                 # monorepo root — clone here
├── omarchy-quattro/             # runtime (= /usr/share/omisu when packaged)
│   ├── bin/
│   ├── config/                  # default dotfiles shipped to users
│   ├── default/                 # plymouth, sddm, branding
│   ├── install/                 # installer hooks
│   └── migrations/              # upgrade scripts (omisu-update)
├── omisu-pkgs/                  # PKGBUILDs
└── omisu-iso/                   # ISO builder
```

On an installed system, `/usr/share/omisu/<path>` maps to
`omarchy-quattro/<path>` in git.

### Workflow

```bash
# One-time on the test box
git clone https://github.com/OmiSU-Dev/OmiSU.git ~/src/OmiSU
cd ~/src/OmiSU

# After fixing (prefer editing the clone, not /usr/share/omisu alone)
omisu-doctor
git checkout -b heal/short-desc
git add omarchy-quattro/...   # only distro paths; never ~/.config
git commit -m "fix: <what broke>"
git push -u origin heal/short-desc
gh pr create --repo OmiSU-Dev/OmiSU --title "fix: ..." --body "..."
```

For fixes that must run on existing installs **and** fresh installs, scaffold a
migration after `omisu-heal`:

```bash
omisu-heal --ship "fix plymouth on virtio-gpu"
# edit omarchy-quattro/migrations/NNNN-*.sh — idempotent, minimal
git add omarchy-quattro/migrations/
```

Quick local test before push (optional):

```bash
sudo cp -a omarchy-quattro/<changed> /usr/share/omisu/<changed>
omisu-doctor
```

### What to commit where

| Change | Git path |
|--------|----------|
| Command / heal logic | `omarchy-quattro/bin/` |
| Default user config | `omarchy-quattro/config/` |
| Boot/login branding | `omarchy-quattro/default/` |
| Installer behavior | `omarchy-quattro/install/` |
| Upgrade hook | `omarchy-quattro/migrations/` |
| PKGBUILD | `omisu-pkgs/pkgbuilds/` |
| Live ISO / installer | `omisu-iso/` |

Do **not** commit `~/.config/*`, passwords, or one-off `/etc` edits unless
promoted into `config/`, `install/`, or a migration.

### Verify with a fresh install

After merge, build an ISO from that commit:

```bash
cd omisu-iso
./bin/omisu-iso-make --no-boot-offer --local-source ../omarchy-quattro ../omisu-pkgs
```

Reinstall bare metal from the release ISO. The fix should apply without copying
files by hand or reusing the old user's home directory.

## Filing a Good Bug Report

```bash
omisu version
omisu debug --no-sudo --print
```

```bash
gh issue create --repo OmiSU-Dev/OmiSU --title "..." --body "..."
```

Include: what happened, expected behavior, steps to reproduce, `omisu-doctor`
output, and a screenshot if visual.

## Submitting a PR

Never develop against `/usr/share/omisu` alone. Clone the monorepo:

```bash
git clone https://github.com/OmiSU-Dev/OmiSU.git
cd OmiSU
```

Edit under `omarchy-quattro/`. Follow `AGENTS.md` for style and testing:

```bash
cd omarchy-quattro && ./test/all
```

Keep commits atomic, open PRs with `gh pr create --repo OmiSU-Dev/OmiSU`.
