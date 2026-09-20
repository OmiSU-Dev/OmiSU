# OmiSU Embedded Play Parity (Lemuroid-class, OmiSU-skinned)

**Date:** 2026-09-17  
**Status:** Implemented (2026-09-17)  
**Goal:** Browse → select → play in-app with Lemuroid-class saves/settings/features across the **full Lemuroid system list (~25)**. Users never see Lemuroid UI, skin, or branding except legal disclosure in About / NOTICE. Startup auto-update pulls latest **LemuroidCores** (and checks **LibretroDroid**) automatically when General Settings auto-update is enabled.

---

## 1. Product rules

1. **Plug and play** — For supported systems, tapping a game launches the embedded player immediately. No “choose Lemuroid,” no Lemuroid menus, no external APK required for those systems.
2. **OmiSU skin only** — All settings and in-game overlay use OmiSU copy, theme, and navigation. Zero Lemuroid strings, icons, package names, or skins in user-facing UI.
3. **Legal disclosure only where required** — About → Open-source / Powered by, plus `NOTICE.md` / GPL. Suggested About line: *“Built-in play powered by LibretroDroid and libretro cores (see NOTICE).”* Optional secondary credit: LemuroidCores as core distribution reference. No “Lemuroid” on play screens or Settings row titles.
4. **Do not ship or deep-fork the Lemuroid app** — Use LibretroDroid (same engine Lemuroid uses) + port needed play logic into OmiSU. Treat `Lemuroid-master` as a reference implementation.

---

## 2. Architecture

```
OmiSU library UI (NeoStation-derived)
  → GameLaunchService
      → if system in EmbeddedCoreRegistry (Android)
          → EmbeddedGameScreen (Flutter overlay + PlatformView)
              → LibretroDroid GLRetroView
              → CoreResolver (bundled .so or LemuroidCores download)
              → OmiSU Saves/States managers
      → else existing external emulator path (Eden, RetroArch, …)
```

| Layer | Source | User-visible name |
|-------|--------|-------------------|
| Frontend / library | OmiSU | OmiSU |
| Play engine | LibretroDroid | (none — invisible) |
| Core binaries | LemuroidCores (pinned tag) or APK `jniLibs` | “Built-in” |
| Saves / settings UX | Ported patterns from Lemuroid | OmiSU Settings / Play |

---

## 3. User experience

### Launch
- Supported system + ROM present → embedded session, no emulator picker.
- Unsupported / Switch-class → existing external intent path unchanged.
- First run for a core: progress overlay (“Preparing built-in player…”), never “Downloading Lemuroid core.”

### In-game overlay (OmiSU)
- Resume, Reset, Mute, Fast-forward (where supported)
- Save / Load slots (4) + autosave row in pause menu
- Exit (flush SRAM + autosave when enabled)
- Core options under “Game options” in pause menu

### Settings (OmiSU → Play / Built-in player)
Port Lemuroid *behavior*, OmiSU labels:

| Setting | Behavior (from Lemuroid) |
|---------|--------------------------|
| Autosave on exit | On by default |
| Shader / picture | Auto, CRT, LCD, Smooth, Sharp + HD mode |
| Immersive display | Hide system bars while playing |
| Haptic / rumble | Device vibration from core rumble events |
| Low-latency audio | Prefer low-latency path |
| Touch controls | On-screen pads when no gamepad (later) |

No separate “Lemuroid settings” section.

### Saves
Mirror Lemuroid’s reliable model under OmiSU paths (names can stay RetroArch-compatible for portability):

| Kind | Intent |
|------|--------|
| SRAM | Battery / cart saves |
| Slot states 1–4 | Manual save states |
| Autosave | Written on clean exit when enabled |
| Previews | Optional thumbnails (later) |

Load path: restore SRAM / last autosave when appropriate after first frame (Lemuroid pattern).

---

## 4. Cores & updates

- **Pin** LemuroidCores version in code (today `1.17.0`); bump deliberately with OmiSU releases.
- Prefer APK-bundled `.so` when present; else download to app storage.
- Optional later: “Built-in player components” update check (separate from Systems JSON auto-update). Never labeled Lemuroid in UI.
- Expanding systems = expand `EmbeddedCoreRegistry` / `CoreMapping` using the same core IDs Lemuroid uses (fceumm, snes9x, gambatte, …).

### System coverage (single release — full Lemuroid list)
All 25 Lemuroid `SystemID` values, mapped to OmiSU `folderName` aliases where they differ (e.g. `ps1` → PSX core, `ngpc` → NGP core, `mame` → MAME2003 Plus). Systems without a NeoStation JSON yet still register in `EmbeddedCoreRegistry` so play works once ROM folders exist.

| Lemuroid ID | OmiSU folder(s) | Core |
|-------------|-----------------|------|
| nes | nes, fc, fds | fceumm |
| snes | snes, sfc | snes9x |
| md | md, genesis | genesis_plus_gx |
| gb / gbc / gba | gb / gbc / gba | gambatte / gambatte / mgba |
| n64 | n64 | mupen64plus_next_gles3 |
| sms / gg | sms, mark3 / gg | genesis_plus_gx |
| psp | psp | ppsspp (+ assets) |
| nds | nds | melonds (default) |
| atari2600 / atari7800 | a26, atari2600 / a78, atari7800 | stella / prosystem |
| psx | ps1 | pcsx_rearmed |
| fbneo / mame2003plus | fbneo, arc / mame | fbneo / mame2003_plus |
| pce | pce, tg16 | mednafen_pce_fast |
| lynx | lynx | handy |
| scd | scd, mcd | genesis_plus_gx |
| ngp / ngc | ngp / ngpc | mednafen_ngp |
| ws / wsc | ws / wsc | mednafen_wswan |
| dos / 3ds | dos / 3ds | dosbox_pure / citra |

### Auto-update (General Settings)
When **Auto-update Systems & Emulators** is ON at startup (alongside existing systems JSON check):

1. **LemuroidCores (OTA, automatic):** Query GitHub latest tag on `Swordfish90/LemuroidCores`. If newer than stored `builtin_cores_version`, download/update all registered core `.so` files for device ABI, prune old version dirs. User-facing copy: “Updating built-in player components…” — never “Lemuroid”.
2. **LibretroDroid (OTA, automatic):** Query GitHub latest stable release on `Swordfish90/LibretroDroid`. If newer than the active engine version, download the matching JitPack AAR, extract JNI libs, and install them into the app native library directory before the first embedded play session. No separate OmiSU APK is required for engine-only upstream releases.
3. **OmiSU app (optional APK):** When **Auto-update App** is ON, check `misobadev/neostation-frontend` releases and prompt to install a newer OmiSU APK when available.
4. **Systems JSON (unchanged):** NeoStation manifest OTA for emulator config definitions — separate from core binaries.

---

## 5. About / legal

- Keep GPL + `NOTICE.md` entries for LibretroDroid, LemuroidCores, and individual cores.
- About screen: short “Powered by” / open-source components list.
- Runtime UI, notifications, and Settings: **no** Lemuroid branding.

---

## 6. Non-goals

- Shipping `com.swordfish.lemuroid` or embedding their Activities/Compose screens
- Matching Lemuroid library/scanner UI (OmiSU already has library)
- Auto-applying every Lemuroid APK release into OmiSU without a deliberate bump
- Replacing Eden/Switch external launch with embedded cores

---

## 7. Success criteria

1. User opens NES (then P1 systems) → play starts in OmiSU with no emulator chooser and no Lemuroid chrome.
2. Autosave + multi-slot save/load work across relaunch.
3. Play settings in OmiSU Settings affect the embedded session.
4. Grep of user-facing strings finds no “Lemuroid” outside About/NOTICE.
5. External emulators still work for non-embedded systems.

---

## 8. Implementation notes (for plan)

Reference trees:
- Engine usage: `Lemuroid-master/.../GameViewModelRetroGameView.kt`, `GameViewModelSaves.kt`, `SettingsManager.kt`
- OmiSU hooks: `embedded_game_screen.dart`, `EmbeddedEmulatorController.kt`, `CoreResolver.kt`, `EmbeddedCoreRegistry`

Next step after approval: implementation plan (P0 → P1 → P2) via writing-plans.
