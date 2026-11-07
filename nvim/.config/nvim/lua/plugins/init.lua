local gh = function(x) return "https://github.com/" .. x end

-- Single source of truth: every plugin this config uses.
--
-- `vim.pack` installs these on first run and pins them in nvim-pack-lock.json.
-- `confirm = false` because this repo's policy is "no prompts" (AGENTS.md rule 3).
vim.pack.add({
  -- UI
  { src = gh("gbprod/nord.nvim") },
  { src = gh("nvim-mini/mini.icons") },
  { src = gh("folke/snacks.nvim") },
  { src = gh("folke/trouble.nvim") },
  { src = gh("nvim-lualine/lualine.nvim") },
  { src = gh("rachartier/tiny-cmdline.nvim") },
  -- Editor
  { src = gh("saghen/blink.cmp"), version = vim.version.range("^1") },
  { src = gh("nvim-mini/mini.pairs") },
  { src = gh("folke/todo-comments.nvim") },
  { src = gh("stevearc/conform.nvim") },
  { src = gh("lewis6991/gitsigns.nvim") },
  { src = gh("MagicDuck/grug-far.nvim") },
  { src = gh("linrongbin16/gitlinker.nvim") },
  { src = gh("folke/which-key.nvim") },
  -- Treesitter
  { src = gh("nvim-treesitter/nvim-treesitter") },
  { src = gh("mks-h/treesitter-autoinstall.nvim") },
  -- LSP
  { src = gh("neovim/nvim-lspconfig") },
  { src = gh("mason-org/mason.nvim") },
  { src = gh("WhoIsSethDaniel/mason-tool-installer.nvim") },
}, { confirm = false })

require("plugins.ui")
require("plugins.editor")
require("plugins.lsp")
require("plugins.treesitter")

-- Plugins whose `plugin/` scripts must be sourced for the config to work.
-- See lua/config/pack.lua for the reasoning.
--
-- This runs during init on purpose: autocmds that these scripts register
-- (notably mason-tool-installer's `VimEnter`) have to be in place before
-- VimEnter fires, otherwise they never run.
local pack = require("config.pack")
for _, name in ipairs(pack.entrypoints) do
  pack.load(name)
end
