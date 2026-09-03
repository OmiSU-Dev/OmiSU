-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- OmiSu's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMISU_PATH") or "/usr/share/omisu") .. "/default/hypr/bootstrap.lua")

-- Disable all OmiSu default bindings. Add your own in hypr/bindings.lua.
-- omisu_default_bindings = false
--
-- Or disable only bindings for OmiSu's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omisu_preinstalled_bindings = false

-- Load OmiSu defaults.
require("default.hypr.omisu")

-- Put your personal overrides in these files. They're loaded after OmiSu's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })
