-- The rewrite (main branch) only handles parser installation; highlighting
-- and indentation are enabled by Neovim itself.
--
-- vim.pack puts the plugin root on 'runtimepath', but nvim-treesitter keeps its
-- queries in `runtime/queries` and relies on `site/queries/<lang>` symlinks to
-- expose them. Those symlinks outlive the install that made them: after a
-- plugin-root move (switching plugin managers, say) they dangle, and
-- treesitter-autoinstall only checks the *parser*, so it thinks the language is
-- installed and never relinks. Highlighting then stays "on" with zero captures —
-- every filetype renders unstyled. Adding the plugin's `runtime` dir directly
-- keeps queries on the installed revision and makes that cache irrelevant.
for _, pack in ipairs(vim.pack.get()) do
  if pack.spec.name == "nvim-treesitter" then
    vim.opt.rtp:append(pack.path .. "/runtime")
  end
end

-- `treesitter-autoinstall` replaces the removed `ensure_installed` option and
-- installs parsers on demand when a filetype is opened.
require("treesitter-autoinstall").setup({
  highlight = true,
})

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
