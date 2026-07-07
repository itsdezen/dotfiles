return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "biome-check", "prettier", stop_after_first = true },
        javascriptreact = { "biome-check", "prettier", stop_after_first = true },
        typescript = { "biome-check", "prettier", stop_after_first = true },
        typescriptreact = { "biome-check", "prettier", stop_after_first = true },
        json = { "biome-check", "prettier", stop_after_first = true },
        css = { "biome-check", "prettier", stop_after_first = true },
        vue = { "prettier" },
        svelte = { "prettier" },
      },
      formatters = {
        ["biome-check"] = {
          condition = function(_, ctx)
            return vim.fs.find(
              { "biome.json", "biome.jsonc" },
              { path = ctx.filename, upward = true }
            )[1] ~= nil
          end,
        },
      },
    },
  },
}
