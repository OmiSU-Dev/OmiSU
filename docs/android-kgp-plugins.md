# Android Kotlin Gradle Plugin (KGP) — Nordi plugins

Flutter will eventually reject plugins that apply their own `kotlin-gradle-plugin` in `buildscript`.

## Status

- **`packages/gamepads_android`** and **`sub_screen`** (pub.dev) still use a legacy `buildscript` + `kotlin-gradle-plugin` classpath. Flutter prints a warning during `assembleGamesirRelease`; builds succeed today. Migrating `gamepads_android` to the declarative `plugins { id 'org.jetbrains.kotlin.android' }` block currently fails under AGP 9.0.1 (`NullPointerException` configuring `:gamepads_android`) — revisit when Flutter’s AGP 9 / `android.newDsl` path is stable.

Rebuild after KGP changes: `./build-utils/build-gamesir-android.sh` from `Nordi/`.
