# Nordi GitHub APK OTA (OmiSU-Dev/OmiSU)

Nordi curated builds poll **GitHub Releases** on [OmiSU-Dev/OmiSU](https://github.com/OmiSU-Dev/OmiSU) when `NordiConfig.enableGithubAppOta` is true. NeoStation (`misobadev/neostation-frontend`) is never used on device.

## First install

Use Wi‑Fi ADB from the monorepo: `../scripts/deploy-nordi-wifi.sh` (see monorepo `docs/nordi-wifi-deploy.md`). OTA only upgrades an existing **same-signature** install.

Uninstall **NeoStation** (`com.neogamelab.neostation`) if it was installed from the old upstream channel.

## GitHub secrets (Production environment)

| Secret | Purpose |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64 of the same `release.jks` used for local Nordi deploys |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASSWORD` | Key password |

Workflow: [`.github/workflows/nordi-android-main.yml`](../.github/workflows/nordi-android-main.yml) runs on every push to `main`.

## Release loop

1. Edit code under this repo.
2. Bump **`version` in `pubspec.yaml`** — increase the `+build` on every `main` push you want phones to see (e.g. `0.12.1+129` → `0.12.1+130`). CI rejects non-increasing builds.
3. Commit and push to `main`.
4. Wait for **Nordi Android (main)** → confirm a **published** release with:
   - `nordi-gamesir-arm64-v8a-<version>.apk`
   - `nordi-gamesir-armeabi-v7a-<version>.apk`
5. On the N30 (Wi‑Fi): cold start with **Check for updates on launch** enabled (default), or Settings → **Check for updates now**.

Verify API from a PC:

```bash
curl -s https://api.github.com/repos/OmiSU-Dev/OmiSU/releases/latest \
  | jq -r '.tag_name, (.assets[].name)'
```

## Monorepo developers

If you edit Nordi inside `Desktop/OmiSU/Nordi`, sync and push from that directory — see monorepo [`docs/nordi-github-sync.md`](../../docs/nordi-github-sync.md).

## Built-in player / cores

LibretroDroid and Lemuroid updates are unchanged (upstream GitHub, not this repo). See `docs/nordi-update-channel.md` in the monorepo.
