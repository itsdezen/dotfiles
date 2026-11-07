-- Lua bytecode cache: must run before any require() so plugin loads hit the cache.
vim.loader.enable()

require("config.options")

-- Plugins first: keymaps.lua relies on the Snacks global, which only exists
-- once snacks.nvim has been set up.
require("plugins")

require("config.keymaps")
require("config.autocmds")
