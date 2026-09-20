# Per-game play tweaks and cheats (built-in / embedded)

## Where to edit

- **Library:** game settings (START / side menu) → **Play** tab (Android + built-in player systems).
- **In-game:** pause menu → **Tweaks & cheats** (same Play UI). **Game options** is still session-only core vars.

Changes apply on the **next** embedded launch of that game.

## Merge order at launch

1. Device profile (`LaunchTuningResolver`)
2. System tuning (`EmbeddedSystemTuning` on Android)
3. **Per-game saved core variables** (`user_roms.embedded_core_variables_json`)
4. In-game pause **Game options** can still change variables for the current session only

## Cheats (LibretroDroid)

Native API (0.13.2): `LibretroDroid.resetCheat()` then `setCheat(index, true, code)` for each **enabled** row (stable list index).

Flutter bridge: `EmbeddedEmulatorService.applyCheats` (full list after each toggle in-game).

Stored in `user_rom_cheats` per ROM. Enabled cheats are applied after the first rendered frame.

RetroArch `.cht` import supports `cheats = N`, `cheatK_desc`, `cheatK_code`.

### libretro-database (community cheat packs)

[libretro-database](https://github.com/libretro/libretro-database) `cht/` trees are the same files RetroArch uses (~250 MB total). They are **cheat codes only** — not core “tweaks” (those stay on the per-core allowlist).

**Bundled pack (Android):** On first launch the app extracts `assets/data/libretro_cheats.tar.gz` (~27 MB compressed, full libretro `cht/` tree) into `{user-data}/libretro-database/cht/`. Release builds run `Nordi/scripts/sync_libretro_cheats_asset.sh` before `flutter build`.

**Play → Import from libretro-database** reads that tree (and optional extra paths):

1. `{user-data}/libretro-database/cht/<System>/<Game>.cht` (default after bootstrap)
2. `{user-data}/cheats/<System>/…`
3. Walking up from the ROM path for `libretro-database-master/cht` (dev PC layouts)
4. Linux desktop: `/usr/share/libretro/database/cht`

Dev symlink (desktop user-data only):

```bash
./Nordi/scripts/install_libretro_cheats.sh
```

Opening **Play / Tweaks & cheats** for a game **auto-imports** cheats from the bundled pack (or a `.cht` next to the ROM) when that game has none saved yet. Matching uses ROM filename and scraped title against `.cht` names (`LibretroCheatSystemMap`). Use **Import from libretro-database** to force a refresh.

RetroAchievements: enabling cheats may affect hardcore mode — the Play tab shows a warning when RA is connected.
