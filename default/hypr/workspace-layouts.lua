-- Restore workspace layouts saved by omisu-hyprland-workspace-layout-toggle.

local paths = require("default.hypr.paths")
local require_all = require("default.hypr.require_all")

local layouts_dir = paths.state_home .. "/omisu/workspace-layouts"

require_all.files(layouts_dir, "omisu.workspace-layouts", { reload = true })
