require("hs.ipc")

-- ── Auto-reload config on save ───────────────────────────────────────────────
local configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", function()
  hs.reload()
end):start()

hs.alert.show("Hammerspoon config loaded")

-- ── Center floating windows on open ──────────────────────────────────────────
-- Mirrors the floating app list in aerospace/.config/aerospace/aerospace.toml.
-- These apps float in AeroSpace, so we center them here on creation; the user
-- can still move them freely afterwards.
hs.window.animationDuration = 0 -- disable Hammerspoon's own move/resize glide globally

local floatingBundleIDs = {
  ["com.apple.systempreferences"] = true,
  ["com.apple.ActivityMonitor"] = true,
  ["com.apple.calculator"] = true,
  ["com.apple.Passwords"] = true,
  ["com.apple.MobileSMS"] = true,
}

local function centerWindow(win)
  if not win or not win:isStandard() then return end
  local screenFrame = win:screen():frame()
  local winFrame = win:frame()
  win:setFrame({
    x = screenFrame.x + (screenFrame.w - winFrame.w) / 2,
    y = screenFrame.y + (screenFrame.h - winFrame.h) / 2,
    w = winFrame.w,
    h = winFrame.h,
  }, 0)
end

local floatingWindowFilter = hs.window.filter.new(function(win)
  local app = win:application()
  return app ~= nil and floatingBundleIDs[app:bundleID()] == true
end)

-- No delay/polling: react on the same tick as window creation, which is the
-- earliest Hammerspoon can intervene. Removes the artificial wait entirely;
-- any residual settle is the app's own post-create layout, not ours.
floatingWindowFilter:subscribe(hs.window.filter.windowCreated, centerWindow)
