# OmiSU

**OmiSU** — the omakase of frontend emulations — is an Android handheld-first fork of [NeoStation](https://github.com/misobadev/neostation-frontend) with embedded libretro cores via [LibretroDroid](https://github.com/Swordfish90/LibretroDroid).

## Alpha scope (Android)

- Default **Retro 82** theme with **JetBrains Mono Nerd Font**
- **Built-in player** for ~25 Lemuroid-supported systems (NES through 3DS, arcade, DOS, etc.)
- Plug-and-play launch: supported ROMs open in-app with no emulator picker and no third-party frontend branding
- **Auto-update** (Settings → General):
  - **Auto-update Systems & Emulators** — OTA libretro cores + LibretroDroid engine + systems JSON
  - **Auto-update App** — OmiSU APK when a new GitHub release is available
- External intent launch preserved for Switch (Eden), RetroArch, and other standalone emulators
- NeoSync, RetroAchievements, ScreenScraper, and multi-disc support retained from NeoStation

## Build (Android)

```bash
cd neostation-frontend-main
flutter pub get
flutter build apk --debug
```

v1 targets **Android only**. Desktop runners are not supported in this alpha.

## Embedded cores

Cores download from LemuroidCores (default tag `1.17.0`, auto-bumped when auto-update runs). Bundled `.so` files under `android/app/src/main/jniLibs/<abi>/` are preferred when present.

LibretroDroid engine can also OTA from JitPack when upstream releases a newer stable version (no OmiSU APK required for engine-only bumps).

Play settings live under **Settings → Playback → Built-in player** (autosave, shaders/HD, immersive, rumble, touch controls, low-latency audio).

Legal attribution: About screen + `NOTICE.md` credit LibretroDroid and libretro cores. Users never see “Lemuroid” in play UI.

## Alpha test checklist

On a real Android arm64 handheld:

1. Install debug APK — **OmiSU** label, **Retro 82** theme, Nerd Font.
2. **NES / SNES / GB / GBA / Genesis** — launch in-app; pause menu (Resume, Mute, Fast-forward, Autosave, Save/Load slots 1–4, Game options, Exit).
3. First launch for a new core — loading overlay shows **Preparing built-in player…** (not Lemuroid branding).
4. Autosave — play, use pause **Save auto**, exit, relaunch; progress restored.
5. **Game options** — open from pause menu; cycle a core option if the core exposes any.
6. **Settings → Playback** — toggle HD/shaders, touch controls, immersive; relaunch game and confirm behavior.
7. **Auto-update on** — restart on Wi‑Fi or mobile data; cores/engine versions in About / Playback update when upstream has newer releases.
8. **Atari 2600 / 7800 / NDS** — folder names route to embedded play when ROMs present.
9. **Switch** — still opens Eden via external intent.
10. Smoke-test NeoSync, RetroAchievements, scraper settings.

## Launcher ambience

OmiSU plays an **original** soft pad loop (`assets/sounds/menu_ambient.wav`) on the home UI. It follows the Interface SFX toggle, pauses when a game launches, and resumes on return.

## Branding

Default theme: **Retro 82** + JetBrains Mono Nerd Font.

Logo assets live under `assets/images/`.

## License

GPL-3.0 — see [LICENSE.md](LICENSE.md) and [NOTICE.md](NOTICE.md).
