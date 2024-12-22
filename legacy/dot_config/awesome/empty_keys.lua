-- Awesome keybindings

-- Importing libraries
local gears = require('gears')
local awful = require('awful')
local vars = require('vars')

-- Variables
local keys = {}

mod = 'Mod4'
tags = 9
keys.tags = tags   --Uncomment this if not using custom tag names
--local terminal = 'kitty'
-- local browser = "firefox"
-- --local editor = "emacsclient --create-frame --no-wait --socket-name=adam-emacsd"
-- local editor = "emacs"

local function local_script(script_name)
  return "/home/adam/10-19.Software/10.Personal-Software/My-Computer/scripts/" .. script_name
end

lock = string.format('sh %s/.local/bin/lock', os.getenv('HOME'))


-- Keybindings
keys.globalkeys = gears.table.join(
  -- Awesome
  awful.key({mod, 'Shift'}, 'r', awesome.restart),
  awful.key({mod, 'Shift'}, 'q', awesome.quit),
  awful.key({mod, 'Shift'}, 'l', function() awful.util.spawn(lock) end),

  --Hardware
  awful.key({}, 'XF86AudioRaiseVolume', function() awful.util.spawn('pactl set-sink-volume @DEFAULT_SINK@ +5%') end),
  awful.key({}, 'XF86AudioLowerVolume', function() awful.util.spawn('pactl set-sink-volume @DEFAULT_SINK@ -5%') end),
  -- Window management
  awful.key({mod}, "j", function () awful.client.focus.byidx(1) end, {description = "focus next by index", group = "client"}),
  awful.key({mod}, "k", function () awful.client.focus.byidx(-1) end, {description = "focus previous by index", group = "client"}),
  awful.key({ mod, "Shift" }, "j", function () awful.client.swap.byidx(1) end, {description = "swap with next client by index", group = "client"}),
  awful.key({ mod, "Shift" }, "k", function () awful.client.swap.byidx( -1) end, {description = "swap with prev client by index", group = "client"}),
  awful.key({mod}, "f", function ()
      -- figure out if I can do this intelligently to always put it on the left side
      awful.client.swap.bydirection('left')
  end,
    {description = "swap current client leftward", group = "client"}
  ),
  awful.key({ mod}, "m", function () awful.layout.inc(1) end, {description = "select next", group = "layout"}),


  awful.key({mod}, "l", function () awful.tag.incmwfact( 0.05) end,{description = "increase master width factor", group = "layout"}),
  awful.key({mod}, "h", function () awful.tag.incmwfact(-0.05) end,{description = "decrease master width factor", group = "layout"}),
  awful.key({mod}, 'Up', function () awful.client.incwfact(0.05) end),
  awful.key({mod}, 'Down', function () awful.client.incwfact(-0.05) end),

  -- Applications
  awful.key({mod}, 'Return', function() awful.util.spawn(vars.terminal) end),
  awful.key({mod}, 'r', function() awful.util.spawn('rofi -show drun') end),
  awful.key({mod}, 'e', function() awful.util.spawn(vars.editor) end),
  awful.key({mod}, 't', function() awful.util.spawn(local_script('rofi-todoist fq')) end),

  awful.key({mod}, "b", function () awful.spawn(vars.browser) end, {description = "open a web browser", group = "launcher"}),

  -- Screenshots
  awful.key({mod, 'Shift'}, "s", function() awful.util.spawn('flameshot gui') end)
)

keys.clientkeys = gears.table.join(
  awful.key({mod}, 'x', function(c) c:kill() end),
  awful.key({mod}, 'space', function(c) c.fullscreen = not c.fullscreen; c:raise() end),
  awful.key({ mod, 'Shift' }, "m",
    function (c)
        c.maximized = not c.maximized
        c:raise()
    end,
    {description = "toggle maximized", group = "client"}),
  awful.key({mod}, 'Tab', function() awful.client.floating.toggle() end),
  awful.key({mod}, 'n', function(c) c.minimized = true end),
  awful.key({ mod, "Control"   }, "n",
    function ()
      for _, c in ipairs(mouse.screen.selected_tag:clients()) do
        c.minimized = false
      end
    end,
    {description = "close all minimized windows in current tag", group = "client"})
)

-- Mouse controls
keys.clientbuttons = gears.table.join(
  awful.button({}, 1, function(c) client.focus = c end),
  awful.button({mod}, 1, function() awful.mouse.client.move() end),
  awful.button({mod}, 2, function(c) c:kill() end),
  awful.button({mod}, 3, function() awful.mouse.client.resize() end)
)

for i = 1, tags do
  keys.globalkeys = gears.table.join(keys.globalkeys,
  -- View tag
  awful.key({mod}, '#'..i + 9,
    function ()
      local tag = awful.screen.focused().tags[i]
      if tag then
         tag:view_only()
      end
    end),
  -- Move window to tag
  awful.key({mod, 'Shift'}, '#'..i + 9,
    function ()
      if client.focus then
        local tag = client.focus.screen.tags[i]
        if tag then
          client.focus:move_to_tag(tag)
        end
     end
    end),
  awful.key({mod, 'Control'}, '#'..i + 9,
    function ()
      local screen = awful.screen.focused()
      local tag = screen.tags[i]
      if tag then
        awful.tag.viewtoggle(tag)
      end
    end))
end

-- Set globalkeys
root.keys(keys.globalkeys)

return keys
