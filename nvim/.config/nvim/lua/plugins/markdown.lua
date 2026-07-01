return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown", "mdx" },
    opts = {
      heading = {
        sign = false,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
      },
      checkbox = {
        unchecked = { icon = "󰄱 " },
        checked   = { icon = "󰱒 " },
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      -- render-markdown.nvim links heading/code backgrounds to Diff*/ColorColumn
      -- via `default = true` highlights set the moment the plugin loads (either
      -- from opening a markdown buffer, or from snacks.nvim's file preview
      -- calling `require("render-markdown")` directly, which bypasses normal
      -- FileType autocmds). Force transparent backgrounds right after setup,
      -- so it applies regardless of what triggered the load.
      for _, name in ipairs({
        "RenderMarkdownH1Bg",
        "RenderMarkdownH2Bg",
        "RenderMarkdownH3Bg",
        "RenderMarkdownH4Bg",
        "RenderMarkdownH5Bg",
        "RenderMarkdownH6Bg",
        "RenderMarkdownCode",
      }) do
        vim.api.nvim_set_hl(0, name, { bg = "none" })
      end
    end,
  },
}
