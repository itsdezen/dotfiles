return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
  keys = {
    { "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", desc = "AI: toggle chat" },
    { "<leader>ai", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "AI: inline assist" },
    { "<leader>ac", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "AI: add to chat" },
    { "<leader>aA", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "AI: actions" },
  },
  opts = {
    adapters = {
      ollama = function()
        return require("codecompanion.adapters").extend("ollama", {
          schema = {
            model = { default = "qwen3:8b" },
          },
        })
      end,
    },
    strategies = {
      chat   = { adapter = "ollama" },
      inline = { adapter = "ollama" },
      agent  = { adapter = "ollama" },
    },
    opts = {
      language = "the same language the user writes in",
    },
    display = {
      chat = { show_settings = true },
    },
  },
}
