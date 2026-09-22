# Nordi

**Dedicated launcher / gaming handheld** build for **OnePlus Nord N30** on **LineageOS / crDroid**, with **GameSir X5 Lite+**.

This is a **separate product line** from [`../neostation-frontend-main`](../neostation-frontend-main) (universal OmiSU for any Android). Do not treat Nordi as a Gradle flavor of the main app: both trees may share history, but **features and defaults diverge on purpose**.

| | Universal OmiSU | Nordi |
| --- | --- | --- |
| Audience | Any Android device | Nord N30 image + controller |
| Setup | Full wizard & library tooling | No wizard; fixed ROM path; trimmed Settings |
| Sync / import | NeoSync, ES-DE, etc. | NeoSync + ES-DE UI removed; **Services** (scraper, RomM, RA) kept |
| Gaming | Frontend + embedded LibretroDroid | **Same stack** — only default playback/tuning seeded at bootstrap |
| Updates | In-app OmiSU / systems OTA | Wi‑Fi deploy for first install; **Check for updates now** pulls the Nordi GitHub APK; optional built-in player cores OTA. NeoStation app and systems JSON stay off. |

Nord-only behavior lives under [`lib/config/nordi_config.dart`](lib/config/nordi_config.dart) (`curatedBuild` is always `true` in this folder).

## What stays the same as OmiSU

- **Embedded play** (LibretroDroid), standalone/RetroArch launch paths, core options, touch overlays, rumble, HD/adaptive HD (with Nordi defaults seeded once).
- **Library**: rescan, add/remove ROM folders (default **`/storage/emulated/0/ROMS`**), appearance, input, playback, streaming, secondary display, about.
- **Settings → Services**: ScreenScraper, RomM panel, RetroAchievements startup match, scrape toggles — **NeoSync row omitted** on Nordi.
- **Sleep tab** (nav): pauses menu audio, dims display, requests screen off (GameSir/BLE may still keep the SoC partially awake — that is normal Android behavior).

## Nordi-only trims

- Setup wizard skipped; bootstrap seeds handheld defaults.
- Top nav: NeoSync, Scraper, RomM, Achievements tabs hidden (Scraper/RomM still reachable from **Services**).
- ES-DE import block removed from Library settings.
- General: **Safe mode** for sideload/dev. **Check for updates now** covers the Nordi GitHub APK and the built-in player. Player cores can also update on launch. NeoStation app and systems JSON stay off. App updates are not checked on launch.
- Settings menu: **Tools** hidden; **Exit** hidden in retail (Safe mode restores Exit + launcher picker).
- **Restart / Reboot** power menu on retail priv-app builds.

## Build (Android)

```bash
cd Nordi
flutter pub get
./build-utils/build-gamesir-android.sh
# or: ./build-utils/build-android.sh  (same gamesir flavor)
```

Uses Gradle flavor **`gamesir`**, `PRELOADED_OEM=true`, and dart-define `NORDI_ROM_ROOT`. Device auto-tune reads hardware at runtime; optional build-time override: `OMISU_DEVICE_PROFILE=nord_n30 ./build-utils/build-gamesir-android.sh`.

Install as system/priv-app on the Nord N30 image for reboot/shutdown and persistent launcher behavior.

### Wi‑Fi deploy (dev)

From the monorepo root (or this folder):

```bash
./scripts/deploy-android-wifi.sh --product nordi
# or: cd Nordi && ./scripts/deploy-android-wifi.sh
```

**Primary guides:** [`../docs/nordi-wifi-deploy.md`](../docs/nordi-wifi-deploy.md) (wireless ADB), [`../docs/nordi-update-channel.md`](../docs/nordi-update-channel.md) (what updates how; NeoStation is not the live channel).

## Relation to universal OmiSU

- **Bug fixes and emulator/embedded work** that apply everywhere: land in `neostation-frontend-main` first, then cherry-pick or re-sync into Nordi when needed.
- **Nordi-only curation** (bootstrap, hidden menus, power/reboot, ROM layout): stay in this tree only.
- Avoid merging the two trees into one “super” branch unless you explicitly decide to collapse product lines.
