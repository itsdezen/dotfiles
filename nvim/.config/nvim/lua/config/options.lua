-- LazyVim sets sane defaults for most options.
-- See: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

vim.diagnostic.config({
  underline = true,
  update_in_insert = false,
  virtual_text = {
    spacing = 4,
    source = "if_many",
    prefix = "●",
  },
  severity_sort = true,
  float = {
    border = "rounded",
    source = "if_many",
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅙",
      [vim.diagnostic.severity.WARN]  = "󰀨",
      [vim.diagnostic.severity.HINT]  = "󰋗",
      [vim.diagnostic.severity.INFO]  = "󰋼",
    },
  },
})
