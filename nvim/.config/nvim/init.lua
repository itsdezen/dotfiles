-- ============================================================================
-- Minimal Modern Neovim Config
-- ============================================================================

-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ============================================================================
-- Options
-- ============================================================================

local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true

-- Indent
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Behavior
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.swapfile = false
opt.backup = false
opt.undofile = true

-- ============================================================================
-- Keymaps
-- ============================================================================

local map = vim.keymap.set

-- Clear search
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Better window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Better indent
map("v", "<", "<gv")
map("v", ">", ">gv")

-- ============================================================================
-- Autocmds
-- ============================================================================

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank()
  end,
})

-- ============================================================================
-- Bootstrap lazy.nvim
-- ============================================================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

-- ============================================================================
-- Plugins
-- ============================================================================

require("lazy").setup({
  -- Theme
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    lazy = false,
    config = function()
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    config = function()
      local telescope = require("telescope")
      local builtin = require("telescope.builtin")

      telescope.setup({
        defaults = {
          path_display = { "truncate" },
        },
      })

      pcall(telescope.load_extension, "fzf")

      map("n", "<leader>ff", builtin.find_files)
      map("n", "<leader>fg", builtin.live_grep)
      map("n", "<leader>fb", builtin.buffers)
      map("n", "<leader>fr", builtin.oldfiles)
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = {
          "lua",
          "vim",
          "vimdoc",
          "javascript",
          "typescript",
          "tsx",
          "html",
          "css",
          "json",
          "yaml",
          "markdown",
          "bash",
        },
        auto_install = true,
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
        },
      })
    end,
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },

    config = function()
      require("mason").setup()

      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "ts_ls",
          "tailwindcss",
        },
      })

      vim.lsp.enable({
        "lua_ls",
        "ts_ls",
        "tailwindcss",
      })

      map("n", "gd", vim.lsp.buf.definition)
      map("n", "gr", vim.lsp.buf.references)
      map("n", "K", vim.lsp.buf.hover)
      map("n", "<leader>rn", vim.lsp.buf.rename)
      map("n", "<leader>ca", vim.lsp.buf.code_action)
    end,
  },

  -- Autocomplete
  {
    "saghen/blink.cmp",
    version = "*",

    opts = {
      keymap = {
        preset = "default",
      },

      appearance = {
        nerd_font_variant = "mono",
      },

      completion = {
        documentation = {
          auto_show = true,
        },
      },

      sources = {
        default = { "lsp", "path", "buffer" },
      },
    },
  },

  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- Comment
  {
    "numToStr/Comment.nvim",
    opts = {},
  },

  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    opts = {},
  },

  -- Which key
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- Formatter
  {
    "stevearc/conform.nvim",

    opts = {
      formatters_by_ft = {
        lua = { "stylua" },

        javascript = { "biome", "prettier" },
        javascriptreact = { "biome", "prettier" },

        typescript = { "biome", "prettier" },
        typescriptreact = { "biome", "prettier" },

        json = { "biome", "prettier" },
        css = { "biome", "prettier" },
      },

      format_on_save = {
        timeout_ms = 2000,
        lsp_fallback = true,
      },
    },

    keys = {
      {
        "<leader>fm",
        function()
          require("conform").format({
            async = true,
            lsp_fallback = true,
          })
        end,
        desc = "Format file",
      },
    },
  },
})

-- ============================================================================
-- End
-- ============================================================================