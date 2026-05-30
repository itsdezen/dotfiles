return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "biome", stop_after_first = true },
        javascriptreact = { "biome", stop_after_first = true },
        typescript = { "biome", stop_after_first = true },
        typescriptreact = { "biome", stop_after_first = true },
        json = { "biome", stop_after_first = true },
        css = { "biome", stop_after_first = true },
      },
    },
  },
}
