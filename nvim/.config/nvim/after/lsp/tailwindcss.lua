---@type vim.lsp.Config
return {
  -- lspconfig ships markdown/mdx/astro-markdown in this list, so the server
  -- spawns for every README in every git repo (its root fallback is `.git`) and
  -- logs a missing-config warning. Tailwind classes live in markup and
  -- components, not in prose.
  filetypes = {
    "html",
    "css",
    "scss",
    "less",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "svelte",
    "astro",
  },
}
