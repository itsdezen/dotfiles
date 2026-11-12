---@type vim.lsp.Config
return {
  single_file_support = true,
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME },
      },
      diagnostics = {
        disable = { "incomplete-signature-doc", "trailing-space" },
        unusedLocalExclude = { "_*" },
      },
    },
  },
}
