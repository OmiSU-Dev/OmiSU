# Monorepo ↔ GitHub sync

Development may happen in `Desktop/OmiSU/Nordi` while this directory is also the git root for [OmiSU-Dev/OmiSU](https://github.com/OmiSU-Dev/OmiSU).

1. Commit inside `Nordi/` (this repo).
2. Bump `pubspec.yaml` `+build` before each OTA-visible push to `main`.
3. `git push origin main` (use `--force` only when replacing unrelated remote history once).
4. First install / sideload from the parent monorepo: `scripts/deploy-nordi-wifi.sh`.

Do not commit `.fvm/`, `build/`, `release/`, keystores, or local `.env`.
