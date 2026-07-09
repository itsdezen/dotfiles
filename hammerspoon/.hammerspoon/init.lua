require("hs.ipc")

-- ── Auto-reload config on save ───────────────────────────────────────────────
local configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function()
  hs.reload()
end):start()

-- Also reload when aerospace.toml changes, since we read the floating app
-- list from it below — keeps the two configs in sync without a manual step.
local aerospaceConfigWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.config/aerospace/", function()
  hs.reload()
end):start()

hs.alert.show("Hammerspoon config loaded")

-- ── Resize + center floating windows on open ─────────────────────────────────
-- These apps float in AeroSpace, so we resize+center them here on creation;
-- the user can still move/resize them freely afterwards.
hs.window.animationDuration = 0 -- instant, no glide

-- Read the floating app list straight from aerospace.toml instead of
-- duplicating it here — avoids the two lists drifting apart or conflicting.
-- Parses '[[on-window-detected]]' blocks of the form:
--   if.app-id = 'com.example.app'
--   run = 'layout floating'
local function loadFloatingBundleIDs()
  local floatingBundleIDs = {}
  local file = io.open(os.getenv("HOME") .. "/.config/aerospace/aerospace.toml", "r")
  if not file then return floatingBundleIDs end
  local pendingAppID = nil
  for line in file:lines() do
    local appID = line:match("^if%.app%-id%s*=%s*'([^']+)'")
    if appID then
      pendingAppID = appID
    elseif pendingAppID and line:find("run%s*=%s*'layout floating'") then
      floatingBundleIDs[pendingAppID] = true
      pendingAppID = nil
    end
  end
  file:close()
  return floatingBundleIDs
end

local floatingBundleIDs = loadFloatingBundleIDs()

local function centerWindow(win)
  if not win or not win:isStandard() then return end
  local screenFrame = win:screen():frame()
  local w = screenFrame.w / 2
  local h = w * 3 / 4
  -- setSize first, then center off the actual resulting frame: some apps
  -- (e.g. System Settings) clamp to their own min/max size, so the frame
  -- we asked for may not be the frame we got.
  win:setSize({ w = w, h = h })
  win:centerOnScreen()
end

local floatingWindowFilter = hs.window.filter.new(function(win)
  local app = win:application()
  return app ~= nil and floatingBundleIDs[app:bundleID()] == true
end)

-- Small delay: some apps still run their own initial layout for a moment
-- after windowCreated fires, which silently overrides an immediate
-- resize/center — the flakiness this delay fixes.
floatingWindowFilter:subscribe(hs.window.filter.windowCreated, function(win)
  hs.timer.doAfter(0.2, function() centerWindow(win) end)
end)
