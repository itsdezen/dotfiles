local pack = require("config.pack")

-- The rewrite (main branch) only handles parser installation; highlighting
-- and indentation are enabled by Neovim itself.
--
-- `treesitter-autoinstall` replaces the removed `ensure_installed` option and
-- installs parsers on demand when a filetype is opened.
--
pack.eager("nvim-treesitter", function()
  require("treesitter-autoinstall").setup({
    highlight = true,
  })
end)

-- Indentation via treesitter. Highlight is handled by treesitter-autoinstall.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TreesitterIndent", { clear = true }),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang or not vim.treesitter.language.add(lang) then
      return
    end
    vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

-- vim.pack has no build hook, so update parsers when the plugin itself changes.
vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("PackHooks", { clear = true }),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
      vim.cmd("TSUpdate")
    end
  end,
})
