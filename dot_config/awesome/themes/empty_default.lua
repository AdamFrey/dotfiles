-- Default
------------------
local gears = require('gears')
local theme = {}

-- TODO is this font automatically installed?
theme.font          = 'Fira Code Medium 10'

theme.useless_gap   = 5
theme.border_width  = 3
theme.border_normal = "#151515" -- TODO set different borders for different apps
theme.border_focus  = "#AA759F"
theme.border_marked = "#151515"
theme.snap_bg = "#D0d0d0"
theme.snap_shape = gears.shape.rectangle

return theme
