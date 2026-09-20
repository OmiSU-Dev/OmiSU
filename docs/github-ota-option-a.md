# Option A — GitHub Actions publishes Nordi releases (OTA)

Goal: after each push to `main`, **Nordi Android (main)** builds signed GameSir APKs and creates a **[GitHub Release](https://github.com/OmiSU-Dev/OmiSU/releases)**. Phones with **Check for updates** (or **check on launch**) download from `releases/latest`.

## SSH deploy keys vs CI secrets

| What you added | Used for |
| --- | --- |
| Deploy key **Updater** (SSH, read/write) | `git push` from a machine — **not** used by Actions to sign APKs |
| **Production** environment secrets below | **Nordi Android (main)** workflow only |

You still need the four **ANDROID_*** secrets even if SSH push works.

## One-time setup (about 10 minutes)

### 1. Create the **Production** environment

On [OmiSU-Dev/OmiSU](https://github.com/OmiSU-Dev/OmiSU):

1. **Settings** → **Environments** → **New environment** → name it **`Production`** (exact spelling).
2. Optional: turn off **Required reviewers** if you want every `main` push to release without approval clicks.

### 2. Add secrets to **Production** (not repository secrets)

**Settings** → **Environments** → **Production** → **Environment secrets** → add:

| Secret name | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Output of the helper script below (entire one line) |
| `ANDROID_KEYSTORE_PASSWORD` | Same as local `storePassword` / `KEYSTORE_PASSWORD` |
| `ANDROID_KEY_ALIAS` | e.g. `upload` or your `KEY_ALIAS` |
| `ANDROID_KEY_PASSWORD` | Same as local `keyPassword` / `KEY_PASSWORD` |

**Must be the same keystore** you use for `./scripts/deploy-nordi-wifi.sh`. Otherwise OTA downloads install but Android rejects them (signature mismatch).

On your PC (from the machine that has `release.jks`):

```bash
cd /path/to/Nordi
export KEYSTORE_PATH=/path/to/your/release.jks   # same file Wi‑Fi deploy uses
bash build-utils/prepare-github-keystore-secret.sh
```

Open the file it prints (e.g. `~/nordi-android-keystore-base64.txt`) and paste into **`ANDROID_KEYSTORE_BASE64`**. Do not commit that file.

### 3. Run the workflow

Either:

- **Actions** → **Nordi Android (main)** → **Run workflow** on `main`, or  
- Push a commit that bumps `pubspec.yaml` build (e.g. `0.12.2+132`).

Wait until the run is **green** (failed step is usually **Setup Android Keystore** when secrets are missing).

### Release changelog (in-app “What’s new”)

Every successful run **must** publish a GitHub Release whose **body** matches the build being shipped:

1. **Bump** `version` in `pubspec.yaml` (`0.12.2+N`) on the commit you push to `main`.
2. Use a **clear commit subject** (it becomes a bullet under “What’s changed”), e.g. `Release 0.12.2+139: fix OTA release notes display.`
3. CI runs `build-utils/generate-github-release-body.sh` (commits since the previous release tag + file/pubspec diffs) and **`verify-github-release-notes.sh`** (fails if the body is empty, missing the version/tag, or still uses the old boilerplate).
4. The Nordi app reads `releases/latest` → `body` and shows it in the update dialog (after the in-app markdown cleanup in `ReleaseNotesDisplay`).

Do **not** hand-edit the workflow `body:` with static text. To fix an already-published release, edit the release on GitHub or re-run notes generation locally and `gh release edit <tag> --notes-file …`.

### 4. Confirm release + app behavior

```bash
# From OmiSU monorepo root
./scripts/verify-nordi-github-ota.sh
```

You should see a tag and `nordi-gamesir-arm64-v8a-….apk` on [Releases](https://github.com/OmiSU-Dev/OmiSU/releases).

On the N30:

- Installed build **lower** than the release (About shows `+build`).
- **Settings → Check for updates now**, or enable **Check for updates on launch** (off by default on curated Nordi bootstrap).

## What users see

- GitHub **repo home** only shows **Releases** in the sidebar after step 3 succeeds — not when code is on `main` alone.
- The app calls `GET …/releases/latest`; no published release → no app update prompt.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| CI fails **Setup Android Keystore** | Add `ANDROID_KEYSTORE_BASE64` on **Production** |
| CI fails **packageGamesirRelease** / `Keystore was tampered with, or password was incorrect` | Base64 is often fine; **password secrets** are wrong. Create `android/key.properties`, run `bash build-utils/verify-android-release-signing.sh`, then `bash build-utils/push-github-android-password-secrets.sh` (no manual paste). |
| CI green, still no Releases | Check **Publish GitHub Release** step log; `contents: write` permission |
| App says up to date | No release yet, or phone build ≥ release build |
| Download OK, install fails | CI keystore ≠ keystore used for the APK on the phone |

See also: [`github-secrets-setup.md`](github-secrets-setup.md), [`github-ota.md`](github-ota.md).
