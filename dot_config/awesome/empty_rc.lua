--      ___
--    /   |_    _____  _________  ________  ___
--   / /| | | /| / / _ \/ ___/ __ \/ __  __ \/ _ \
--  / ___ | |/ |/ /  __(__  ) /_/ / / / / / /  __/
-- /_/  |_|__/|__/\___/____/\____/_/ /_/ /_/\___/

-- AWESOME CONFIG (~/.config/awesome/rc.lua)
-------------------------------------------------------
-- Importing libraries
local gears = require('gears')
local awful = require('awful')
local wibox = require('wibox')
require('awful.autofocus')
local beautiful = require('beautiful')
local keys = require('keys')

-- Variables
theme_path = string.format('%s/.config/awesome/themes/%s.lua', os.getenv('HOME'), 'default')
beautiful.init(theme_path)

-- Layouts
awful.layout.layouts = {
  --awful.layout.suit.tile,
  awful.layout.suit.spiral.dwindle,
  --awful.layout.suit.max,
  --awful.layout.suit.magnifier,
  --awful.layout.suit.tile.bottom,
  --awful.layout.suit.tile.top,
  --awful.layout.suit.corner.nw,
  awful.layout.suit.fair,
  -- awful.layout.suit.fair.horizontal,
  --awful.layout.suit.spiral,
  --awful.layout.suit.max.fullscreen,
  --awful.layout.suit.corner.ne,
  --awful.layout.suit.corner.sw,
  --awful.layout.suit.corner.se,
  --awful.layout.suit.floating,
}

-- Virtual desktops/ Tabs
awful.screen.connect_for_each_screen(function(s)
  local tagTable = {'1', '2', '3', '4', '5'}

  -- Uncomment this if not using custom tag names (no. of tags will be derived from `tags` variable set in keys.lua)
  -- Also uncomment `keys.tags = tags` line in the Variables section in keys.lua!
  local tagTable = {}
  for i = 1, keys.tags do
    table.insert(tagTable, tostring(i))
  end

  awful.tag(tagTable, s, awful.layout.layouts[1])
end)

awful.rules.rules = {
  -- All windows
  { rule = { },
    properties = { border_width = beautiful.border_width,
           focus = awful.client.focus.filter,
           raise = true,
           keys = keys.clientkeys,
           buttons = keys.clientbuttons,
           screen = awful.screen.preferred,
           placement = awful.placement.no_overlap+awful.placement.no_offscreen,
           -- https://awesomewm.org/apidoc/documentation/90-FAQ.md.html why some floating clients can not be tiled?
           maximized_vertical   = false,
           maximized_horizontal = false
           }
  },

  -- Floating exceptions
  --{ rule_any = {
  --    class = {'Lxappearance', 'qt5ct'},
  --    name = {'Event Tester'}, --xev
  --    role = {'pop-up', 'GtkFileChooserDialog'},
  --    type = {'dialog'}
  --  },
  --  properties = {floating = true}
  --}
}

-- Enable sloppy focus
client.connect_signal('mouse::enter', function(c)
  c:emit_signal('request::activate', 'mouse_enter', {raise = false})
end)

-- Colored borders
client.connect_signal('focus', function(c)
  c.border_width = 3
  c.border_color = beautiful.border_focus
end)
client.connect_signal('unfocus', function(c)
                        c.border_width = beautiful.border_width
                        c.border_color = beautiful.border_normal
end)

-- Autostart
awful.spawn.with_shell('$HOME/.config/polybar/launch.sh')
awful.spawn.with_shell('dunst')
-- awful.spawn.with_shell('picom') -- My rinkydink videocard can't handle picom
awful.spawn.with_shell('feh --bg-fill -r -z ~/30-39.Images/30.Wallpapers')
awful.spawn.with_shell('flameshot')
awful.spawn.with_shell('xrdb -merge $HOME/.Xresources')
awful.spawn.with_shell('xset r rate 240 40')
awful.spawn.with_shell('setxkbmap -option \'caps:ctrl_modifier\'')
awful.spawn.with_shell('xmodmap -e "keycode 135 = Super_R"')
-- awful.spawn.with_shell('usv restart emacs') -- emacs server seems like it was being started too early so give it a restart on WM load

-- Garbage Collection
-- collectgarbage('setpause', 110)
-- collectgarbage('setstepmul', 1000)
