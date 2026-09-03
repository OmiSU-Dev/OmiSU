# OmiSu CLI

OmiSu is usually controlled through the hotkeys and the OmiSu menu (`Super + Space`). But you can also control it through the `omisu` CLI. This is particularly helpful when you're having an AI agent work with you on customization or configuration.

The CLI has access to all the internal tooling that is used both via the menu and otherwise. You can see everything that's available by running `omisu` in the terminal.

It looks something like this:

```
~ ❯ omisu
OmiSu command center

Usage:
  omisu <command> [args...]
  omisu commands [--all] [--json] [--check]
  omisu <group> --help
  omisu <group> <command> --help

Common commands:
  omisu update              Update OmiSu and system packages
  omisu theme list          List available themes
  omisu theme set <name>    Apply a theme
  omisu font list           List available fonts
  omisu screenshot          Take a screenshot
  omisu debug               Print debugging information

Groups:
  agent          AI coding agent usage data
  audio          Audio input and output controls
  bar            OmiSu shell bar layout and settings
  battery        Battery status helpers
  bluetooth      Bluetooth device controls
  branch         OmiSu git branch management
  branding       About and screensaver branding
  brightness     Display and keyboard brightness
  capture        Screenshots and screen recording
  channel        OmiSu release channel management
  clipboard      Clipboard helpers
  cmd            Command and shortcut helpers
  config         System configuration helpers
  debug          Diagnostics and support logs
  ...
```

And you can dive deeper on every group:

```
~ ❯ omisu capture
Capture commands — Screenshots and screen recording:
  omisu capture qr                                                                                                                                                                                                       Decode a QR code from a screenshot region
  omisu capture screenrecording [--fullscreen] [--with-desktop-audio] [--with-microphone-audio] [--with-webcam] [--webcam-device=<device>] [--webcam-size=<small|medium|large>] [--resolution=<size>] [--stop-recording]  Start or stop screen recording
  omisu capture screenrecording with webcam                                                                                                                                                                              Pick a webcam and start a screen recording with it
  omisu capture screenshot [smart|region|windows|fullscreen] [slurp|copy|save] [--editor=<name>]                                                                                                                         Take a screenshot
  omisu capture text                                                                                                                                                                                                     Extract text from a screenshot region with OCR
  omisu capture webcam resize <smaller|larger|reset|small|medium|large>                                                                                                                                                  Resize the active webcam recording overlay
```

Every command takes `--help` too, whether you ask a whole group (`omisu capture --help`) or a single command (`omisu capture screenshot --help`).

### Opening the menu from the terminal

The OmiSu menu is scriptable as well, which is handy for your own keybindings. `omisu menu` opens it at the root, and you can jump straight to any point in the tree by naming it: `omisu menu summon style.theme` goes right to the theme picker, `omisu menu toggle system` opens the system menu and closes it again if it's already up, and `omisu menu close` puts it away.
