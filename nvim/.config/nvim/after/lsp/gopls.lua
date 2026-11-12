---@type vim.lsp.Config
return {
  settings = {
    gopls = {
      gofumpt = true,
      completeUnimported = true,
      staticcheck = true,
    },
  },
}
