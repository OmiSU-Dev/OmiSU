---
title: Troubleshooting
layout: default
nav_order: 7
---

# Troubleshooting

## My games do not appear

1. Open **Settings → Directories** and confirm the ROM folder is listed.
2. Select **Rescan All ROM Folders**.
3. Check that the games are in a supported format for the detected system.
4. On Android, grant access again by choosing the ROM folder through the system picker.

## A game will not launch

Check the emulator configured for that system. NeoStation can report missing RetroArch, a missing RetroArch executable or core directory, a missing core, a missing standalone executable, or an unconfigured emulator. Configure or reinstall the item named in the message, then try again.

## Scraping fails

Confirm that you are signed in to ScreenScraper and that the game system is mapped. A successful metadata request can still have failed media downloads; retry after checking your connection.

## RetroAchievements has no matches

Run **Settings → Tools → Match RetroAchievements Games**. Matching a large library can take time and may be paused and resumed. Sign in to the RetroAchievements tab to view results.

## A NeoSync save is not appearing on another device

1. Sign in to NeoSync on the same account on every device, and confirm sync is turned on.
2. Let each device sync once (start the app, or launch a game) before looking for the save.
3. Open the **NeoSync → Save List** to confirm the file exists in the cloud at all.
4. Check the save status on the game itself. **Local only** means the file has not been uploaded yet; **Cloud only** means it is waiting to be downloaded.
5. If it is a standalone emulator save, confirm the emulator has a **Custom Save Folder** configured on the device where you expect the file.
6. If the file is on the other device but shows the wrong emulator, delete the duplicate in the [NeoSync web view](https://neosync.cloud/) and let the device re-upload.

If the save still does not appear, gather the device `app.log` and its platform, NeoStation version, system, emulator and the exact filename, then open an issue. The log reports where each save was written and why a download failed, including permission errors.

## Steam Deck controls feel wrong

Launch NeoStation from Steam. See [Steam Deck & SteamOS](/platforms/steam-deck-and-steamos/) for the lizard-mode symptoms and setup.

## Collecting Useful Information

When opening an issue, include your platform, NeoStation version, the system and emulator involved, the exact error message, and whether the problem happens after a rescan or restart. Do not share account passwords or API keys.

## Related Pages

- [Getting Started](/getting-started/getting-started/)
- [Configuring Emulators](/configuration/configuring-emulators/)
- [Scraping & Metadata](/features/scraping-and-metadata/)
