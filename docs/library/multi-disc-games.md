---
title: Multi-Disc Games
layout: default
parent: Library
nav_order: 2
---

# Multi-Disc Games

**Organize Multi-Disc Games** finds recognised disc sets, puts each set in a game folder, and creates an `.m3u` playlist for emulators that use one.

## Before You Start

Back up your ROM library if you do not want NeoStation to rearrange it. This tool moves files.

NeoStation only processes recognised ROM extensions for configured systems.

## Organise Your Library

1. Open **Settings → Tools**.
2. Select **Organize Multi-Disc Games**.
3. Wait for the scan and completion message.

The tool searches configured ROM folders, including the relevant system folders, and supports both desktop folders and Android Storage Access Framework locations.

## Recognised Names

The filename must contain a `Disc`, `Disk`, or `CD` marker followed by a number. For example:

- `Example Game (Disc 1).chd`
- `Example Game (Disk 2).chd`
- `Example Game CD 03.iso`

For each set, NeoStation creates a folder named after the game, moves the disc files into it, and writes a playlist named `<game>.m3u`. Playlist entries use the moved filenames.

Existing `.m3u` files are moved into the game folder when appropriate. A directory whose own name ends in `.m3u`, or which is inside one, is skipped to avoid reprocessing a playlist directory.

## Limitations

- Sets without one of the recognised markers are not grouped.
- The organiser does not delete disc images.
- A missing or inaccessible configured folder is skipped and reported in the result.

## Related Pages

- [Adding Your Games](/library/adding-your-games/)
- [Troubleshooting](/troubleshooting/)
