# OmiSU Full Embedded Play Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship plug-and-play in-app play for all ~25 Lemuroid-supported systems inside OmiSU (no Lemuroid branding), with Lemuroid-class saves/settings, and startup auto-update of LemuroidCores + LibretroDroid version checks when General Settings auto-update is enabled.

**Architecture:** Expand `EmbeddedCoreRegistry` / `CoreMapping` to the full Lemuroid system→core map (with OmiSU folder aliases). Port Lemuroid save/state and play-settings logic into Kotlin (`EmbeddedEmulatorController`) + Flutter (`embedded_game_screen`, new Settings → Play section). Add `BuiltinPlayerUpdateService` that queries GitHub for latest LemuroidCores tag (OTA core download) and LibretroDroid release (prompt app update if newer than bundled). Hook into existing startup flow in `app_screen.dart` when `autoUpdateSystems` is ON.

**Tech Stack:** Flutter/Dart, Kotlin, LibretroDroid 0.13.2, LemuroidCores (dynamic tag), SQLite config, GitHub REST API.

## Global Constraints

- No user-facing “Lemuroid” strings outside About / NOTICE / open-source list.
- Plug and play: supported Android system → embedded launch, no emulator picker.
- Full Lemuroid system list (~25) in one release, not phased by platform.
- Auto-update on startup when `autoUpdateSystems` is enabled: OTA LemuroidCores; LibretroDroid check only (requires APK for engine bump).
- OmiSU skin/theme for all overlays and settings.
- GPL attribution preserved in About + `NOTICE.md`.

---

### Task 1: Full system→core registry (Dart + Kotlin)

**Files:**
- Modify: `lib/models/embedded_core_config.dart`
- Modify: `android/app/src/main/kotlin/com/omisu/embedded/CoreMapping.kt`
- Create: `lib/models/embedded_system_aliases.dart` (folder alias → canonical system id)
- Test: `test/models/embedded_core_registry_test.dart`

**Interfaces:**
- Consumes: Lemuroid `SystemID.kt` + `CoreID.kt` mapping (reference only)
- Produces:
  - `EmbeddedCoreRegistry.supports(folderName) -> bool`
  - `EmbeddedCoreRegistry.configFor(folderName) -> EmbeddedCoreConfig?`
  - `CoreMapping.forSystem(systemId) -> CoreMapping?` for all 25 systems + aliases (`ps1`, `ngpc`, `mame`, `fc`, `fds`, `sfc`, `genesis`, `mcd`, `tg16`, `arc`, `mark3`, etc.)

- [ ] **Step 1: Write failing registry test**

```dart
test('ps1 folder maps to pcsx_rearmed core', () {
  expect(EmbeddedCoreRegistry.supports('ps1'), isTrue);
  expect(EmbeddedCoreRegistry.configFor('ps1')!.coreFileName,
      'libpcsx_rearmed_libretro_android.so');
});
```

- [ ] **Step 2: Run test — expect FAIL**

Run: `flutter test test/models/embedded_core_registry_test.dart`
Expected: FAIL (ps1 not registered)

- [ ] **Step 3: Implement full registry in Dart**

Add all entries from spec table. Each `EmbeddedCoreConfig` includes `systemId`, `coreFileName`, `coreName` (LemuroidCores path segment), `extensions` (from Lemuroid `GameSystem.uniqueExtensions` where applicable).

- [ ] **Step 4: Mirror in Kotlin `CoreMapping` enum**

One entry per unique core; `forSystem()` resolves aliases via shared map.

- [ ] **Step 5: Run test — expect PASS**

- [ ] **Step 6: Commit**

```bash
git add lib/models/embedded_core_config.dart lib/models/embedded_system_aliases.dart \
  android/app/src/main/kotlin/com/omisu/embedded/CoreMapping.kt \
  test/models/embedded_core_registry_test.dart
git commit -m "feat: register full Lemuroid system list for embedded play"
```

---

### Task 2: Dynamic LemuroidCores version in CoreResolver

**Files:**
- Modify: `android/app/src/main/kotlin/com/omisu/embedded/CoreResolver.kt`
- Create: `android/app/src/main/kotlin/com/omisu/embedded/BuiltinCoresStore.kt`
- Modify: `android/app/src/main/kotlin/com/omisu/embedded/EmbeddedEmulatorPlugin.kt` (expose version getter)

**Interfaces:**
- Consumes: `CoreMapping` from Task 1
- Produces:
  - `BuiltinCoresStore.getActiveVersion(context): String`
  - `BuiltinCoresStore.setActiveVersion(context, version: String)`
  - `CoreResolver.resolve(context, mapping): File` uses active version dir, not hardcoded `1.17.0`

- [ ] **Step 1: Replace `CORES_VERSION` constant with SharedPreferences-backed store** (default `1.17.0`)

- [ ] **Step 2: Download URL builder**

```kotlin
"$CORES_BASE/raw/$version/lemuroid_core_${mapping.coreName}/src/main/jniLibs/$abi/${mapping.libretroFileName}"
```

- [ ] **Step 3: Prune old version directories on version bump** (Lemuroid `deleteOutdatedCores` pattern)

- [ ] **Step 4: MethodChannel `getBuiltinCoresVersion` for Flutter About/settings**

- [ ] **Step 5: Manual verify — launch NES still resolves bundled/downloaded core**

Run: install debug APK, launch NES ROM

- [ ] **Step 6: Commit**

---

### Task 3: BuiltinPlayerUpdateService (LemuroidCores OTA + LibretroDroid check)

**Files:**
- Create: `lib/services/builtin_player_update_service.dart`
- Create: `android/app/src/main/kotlin/com/omisu/embedded/BuiltinCoreUpdater.kt`
- Modify: `lib/screens/app_screen.dart` (hook startup)
- Modify: `lib/data/datasources/sqlite_service.dart` + migration (optional `builtin_cores_version`, `libretrodroid_checked_version` columns)
- Modify: `lib/l10n/app_locale_en.dart` (user strings — no “Lemuroid”)

**Interfaces:**
- Consumes: `config.autoUpdateSystems`, MethodChannel core download APIs
- Produces:
  - `BuiltinPlayerUpdateService.checkAndUpdate({required bool silent}) -> BuiltinPlayerUpdateResult`
  - `BuiltinCoreUpdater.downloadAllCores(version: String): Int` (Kotlin, background thread)
  - GitHub endpoints:
    - `GET https://api.github.com/repos/Swordfish90/LemuroidCores/tags` → latest tag
    - `GET https://api.github.com/repos/Swordfish90/LibretroDroid/releases/latest` → compare to `0.13.2`

- [ ] **Step 1: Implement GitHub tag fetch with 15s timeout + fallback to bundled version on network error**

- [ ] **Step 2: If LemuroidCores tag > stored version, download all cores registered in Task 1 for device ABI**

Progress toast: `AppLocale.builtinPlayerUpdating` → “Updating built-in player components…”

- [ ] **Step 3: Persist new cores version on success; do not persist on partial failure**

- [ ] **Step 4: LibretroDroid version compare**

If `remote > bundled`, set flag consumed by existing app-update check or show non-blocking snackbar: “A new OmiSU build is recommended for the latest built-in player engine.” Do **not** attempt runtime native swap.

- [ ] **Step 5: Wire into `_runStartupSequence` in `app_screen.dart` immediately after/before systems JSON update when `autoUpdateSystems` is true**

- [ ] **Step 6: Commit**

---

### Task 4: Saves & states parity (SRAM + 4 slots + autosave)

**Files:**
- Create: `android/app/src/main/kotlin/com/omisu/embedded/EmbeddedSavesManager.kt`
- Modify: `android/app/src/main/kotlin/com/omisu/embedded/EmbeddedEmulatorController.kt`
- Modify: `android/app/src/main/kotlin/com/omisu/embedded/EmbeddedEmulatorPlugin.kt`
- Modify: `lib/services/embedded/embedded_emulator_service.dart`
- Reference: `Lemuroid-master/.../StatesManager.kt`, `SavesManager.kt`, `GameViewModelSaves.kt`

**Interfaces:**
- Produces:
  - Paths: `{filesDir}/omisu/saves/{coreName}/{romBasename}.srm`, `{filesDir}/omisu/states/{coreName}/{romBasename}.slot{1-4}`, `.state` autosave
  - `saveState(slot: Int): Boolean`, `loadState(slot: Int): Boolean`, `autosaveOnExit(): Boolean`, `restoreSramAfterFirstFrame(): Boolean`
  - MethodChannel methods mirrored in Dart `EmbeddedEmulatorService`

- [ ] **Step 1: Implement directory layout matching Lemuroid (RetroArch-compatible basenames)**

- [ ] **Step 2: On `createRetroView`, set `saveRAMState` appropriately; after first frame load autosave or SRAM**

- [ ] **Step 3: On `unload`/`dispose`, flush SRAM + autosave when setting enabled (Task 6)**

- [ ] **Step 4: Gzip state files optional — match Lemuroid if LibretroDroid returns raw bytes (document choice in code comment)**

- [ ] **Step 5: Replace single `slot0.state` with slot API**

- [ ] **Step 6: Commit**

---

### Task 5: In-game overlay (OmiSU pause menu)

**Files:**
- Modify: `lib/screens/embedded_game_screen.dart`
- Create: `lib/widgets/embedded/embedded_pause_menu.dart`
- Modify: `lib/services/embedded/embedded_emulator_service.dart` (mute, fastForward, reset)

**Interfaces:**
- Produces overlay actions: Resume, Reset, Mute, Fast-forward (if supported), Save slot 1–4, Load slot 1–4, Exit (with autosave)

- [ ] **Step 1: Build OmiSU-styled bottom/side sheet using current theme (Retro 82 / active theme)**

- [ ] **Step 2: Wire gamepad B = menu toggle, A = confirm (existing navigation patterns)**

- [ ] **Step 3: Wire MethodChannel for `setAudioEnabled`, `setFrameSpeed`, existing save/load slots**

- [ ] **Step 4: Remove raw “Save state stored” debug snackbars; use localized strings**

- [ ] **Step 5: Commit**

---

### Task 6: Play settings in OmiSU Settings (Lemuroid behavior, OmiSU labels)

**Files:**
- Create: `lib/screens/settings_screen/new_settings_options/play_settings_content.dart`
- Modify: `lib/screens/settings_screen/new_settings_screen.dart`
- Modify: `lib/models/config_model.dart` + sqlite migration v162+
- Modify: `lib/providers/sqlite_config_provider/mutators.dart`
- Modify: `lib/l10n/app_locale.dart`, `app_locale_en.dart`
- Modify: `android/.../EmbeddedEmulatorController.kt` (apply shader, immersive, rumble, low-latency from tuning)

**Settings rows (defaults match Lemuroid):**
- Autosave on exit (bool, default true)
- Picture filter / shader (enum: auto, crt, lcd, smooth, sharp)
- HD mode + quality
- Immersive mode
- Haptic / rumble
- Low-latency audio

Section title: **Play** or **Built-in player** — not “Lemuroid”.

- [ ] **Step 1: Add config columns + mutators**

- [ ] **Step 2: Settings UI rows with NeoGlass styling**

- [ ] **Step 3: Pass settings into `LaunchTuning` / `GLRetroViewData.shader` via `ShaderChooser` port (create `lib/services/embedded/shader_config.dart` + Kotlin mirror of Lemuroid `ShaderChooser.kt`)**

- [ ] **Step 4: Commit**

---

### Task 7: PPSSPP assets + heavy-core bootstrap

**Files:**
- Create: `android/app/src/main/kotlin/com/omisu/embedded/PpssppAssetsManager.kt`
- Modify: `android/app/src/main/kotlin/com/omisu/embedded/BuiltinCoreUpdater.kt`
- Reference: `Lemuroid-master/.../PPSSPPAssetsManager.kt`

- [ ] **Step 1: Port PPSSPP asset download into `{filesDir}/omisu/system/` before first PSP launch**

- [ ] **Step 2: Trigger asset fetch during core update pass for PSP core**

- [ ] **Step 3: Smoke-test PSP launch on arm64 device/emulator**

- [ ] **Step 4: Commit**

---

### Task 8: Mark systems for embedded launch in JSON + launch path

**Files:**
- Modify: `assets/systems/*.json` for all embedded-supported ids (add `"embedded_core": true` where missing — follow `nes.json` pattern)
- Modify: `lib/services/game/game_launch_service.dart` (ensure alias folders resolve via `EmbeddedCoreRegistry`)
- Modify: `lib/services/systems_update_service.dart` (preserve `embedded_core` flag on OTA merge if applicable)

- [ ] **Step 1: Add `"embedded_core": true` to: nes, snes, md, genesis, gb, gbc, gba, n64, sms, gg, psp, ps1, fbneo, mame, pce, lynx, scd, ngp, ngpc, ws, wsc, dos, 3ds, and alias files (fc, fds, sfc, mcd, tg16, arc, mark3)**

- [ ] **Step 2: Confirm launch bypasses external emulator picker for these folders on Android**

- [ ] **Step 3: Commit**

---

### Task 9: Rumble + immersive + core variables wiring

**Files:**
- Modify: `android/.../EmbeddedEmulatorController.kt`
- Create: `android/.../EmbeddedRumbleManager.kt`
- Modify: `lib/services/launch/launch_tuning_resolver.dart`

- [ ] **Step 1: Consume `getRumbleEvents()` → `Vibrator` when play setting enabled**

- [ ] **Step 2: Apply `ImmersiveMode` on `GLRetroViewData` from config**

- [ ] **Step 3: Per-system core variables from Lemuroid defaults (start with NES overscan, Genesis filter) via tuning map**

- [ ] **Step 4: Commit**

---

### Task 10: About / legal disclosure

**Files:**
- Modify: `lib/screens/settings_screen/new_settings_options/about_settings_content.dart`
- Modify: `NOTICE.md`
- Modify: `lib/l10n/app_locale_en.dart`

- [ ] **Step 1: Add About subsection “Open-source components”**

Copy:
> Built-in play is powered by LibretroDroid and libretro cores distributed via LemuroidCores. See NOTICE for licenses.

- [ ] **Step 2: Show `Built-in cores: {version}` from MethodChannel**

- [ ] **Step 3: Show `LibretroDroid: {bundledVersion}` + optional “update available” hint**

- [ ] **Step 4: Commit**

---

### Task 11: Integration tests & alpha checklist

**Files:**
- Modify: `OMISU.md` alpha checklist
- Test: expand `embedded_core_registry_test.dart`, add `builtin_player_update_service_test.dart` (mock HTTP)

- [ ] **Step 1: Unit tests for registry aliases + version compare logic**

- [ ] **Step 2: Update OMISU.md with full system list + auto-update behavior**

- [ ] **Step 3: Manual alpha matrix on arm64 handheld:**

| System | Launch in-app | Save/load | Autosave |
|--------|---------------|-----------|----------|
| NES | | | |
| SNES | | | |
| GB/GBC/GBA | | | |
| Genesis/SMS/GG | | | |
| PS1 | | | |
| PSP | | | |
| … | | | |

- [ ] **Step 4: Commit**

---

## Spec self-review

| Spec requirement | Task |
|------------------|------|
| Full ~25 systems | Task 1, 8 |
| No Lemuroid branding in UI | Tasks 5, 6, 10 + Global Constraints |
| Plug and play launch | Tasks 1, 8 |
| Lemuroid-class saves | Task 4 |
| Lemuroid-class settings/overlay | Tasks 5, 6, 9 |
| Auto-update LemuroidCores OTA | Task 2, 3 |
| Auto-check LibretroDroid | Task 3, 10 |
| About legal disclosure | Task 10 |
| PPSSPP / heavy cores | Task 7 |

**LibretroDroid runtime limitation (documented):** engine updates require a new OmiSU APK; startup check notifies user, does not silently patch native code.

---

## Execution order

1 → 2 → 3 (registry + cores + update) in parallel with 4 → 5 → 6 (play UX)  
7 after 2  
8 after 1  
9 after 6  
10 anytime after 3  
11 last
