--- Thin wrapper around Neovim 0.12's built-in `vim.pack`.
---
--- `vim.pack.add()` during init.lua sourcing uses `:packadd!`: the plugin's Lua
--- modules become requireable, but its `plugin/` scripts (user commands and
--- autocmds) are NOT sourced. `pack.load()` closes that gap.
---
--- Every plugin is set up eagerly. Neovim's own startup is fast enough, and
--- lazy loading under `vim.pack` needs enough custom machinery -- deferred
--- `:packadd`, manual runtimepath handling, event ordering -- that it costs
--- more complexity than it saves.
local M = {}

--- Plugins whose `plugin/` scripts must be sourced for the config to work.
---
--- - blink.cmp            -> sets `vim.lsp.config('*', { capabilities = ... })`
---                          globally and defines `:BlinkCmp`
--- - nvim-treesitter      -> defines `:TSInstall` / `:TSUpdate`
--- - mason-tool-installer -> registers a `VimEnter` autocmd that installs the
---                          tools listed in `ensure_installed`
--- - which-key            -> defines `:WhichKey`
M.entrypoints = {
  "blink.cmp",
  "nvim-treesitter",
  "mason-tool-installer",
  "which-key",
}

---@type table<string, fun()>
local setups = {}

---@type table<string, boolean>
local loaded = {}

--- Source a plugin's `plugin/` scripts and run its setup (once).
---@param name string
function M.load(name)
  if loaded[name] then return end
  loaded[name] = true
  pcall(vim.cmd.packadd, name)
  local fn = setups[name]
  if fn then fn() end
end

--- Register and immediately run a plugin's setup.
---@param name string
---@param fn fun()
function M.eager(name, fn)
  setups[name] = fn
  M.load(name)
end

return M
