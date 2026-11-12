---@type vim.lsp.Config
return {
  settings = {
    complete_function_calls = true,
    vtsls = {
      autoUseWorkspaceTsdk = true,
      enableMoveToFileCodeAction = true,
    },
    typescript = {
      updateImportsOnFileMove = { enabled = "always" },
    },
  },
}
