local gh = function(x) return "https://github.com/" .. x end

-- Single source of truth: every plugin this config uses.
--
-- `vim.pack` installs these on first run and pins them in nvim-pack-lock.json.
-- `confirm = false` because this repo's policy is "no prompts" (AGENTS.md rule 3).
--
-- `load = true` sources each plugin's `plugin/` and `ftdetect/` scripts. Without
-- it those stay unsourced until something calls `:packadd`, which silently
-- breaks plugins that register their commands or autocmds there.
vim.pack.add({
  -- UI
  { src = gh("ellisonleao/gruvbox.nvim") },
  { src = gh("nvim-mini/mini.icons") },
  { src = gh("folke/snacks.nvim") },
  { src = gh("akinsho/bufferline.nvim") },
  { src = gh("folke/which-key.nvim") },
  { src = gh("nvim-lualine/lualine.nvim") },
  -- Editor
  { src = gh("stevearc/conform.nvim") },
  { src = gh("lewis6991/gitsigns.nvim") },
  { src = gh("esmuellert/codediff.nvim") },
  -- Treesitter
  { src = gh("nvim-treesitter/nvim-treesitter") },
  { src = gh("mks-h/treesitter-autoinstall.nvim") },
  -- LSP
  { src = gh("neovim/nvim-lspconfig") },
  { src = gh("mason-org/mason.nvim") },
  { src = gh("WhoIsSethDaniel/mason-tool-installer.nvim") },
}, { confirm = false, load = true })

require("plugins.ui")
require("plugins.editor")
-- mason first: it puts its bin dir on vim.env.PATH before any client can spawn.
require("plugins.mason")
require("plugins.lsp")
require("plugins.treesitter")
