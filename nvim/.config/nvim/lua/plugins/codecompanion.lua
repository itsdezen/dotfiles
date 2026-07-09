return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
  keys = {
    { "<leader>A", nil, desc = "AI local/CodeCompanion" },
    { "<leader>Aa", "<cmd>CodeCompanionChat Toggle<cr>", desc = "AI local: toggle chat" },
    { "<leader>Ai", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "AI local: inline assist" },
    { "<leader>Ac", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "AI local: add to chat" },
    { "<leader>AA", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "AI local: actions" },
    -- alias /commit is shadowed by the builtin prompt, which resolves first
    { "<leader>gm", "<cmd>CodeCompanion /gitmoji<cr>", desc = "AI: commit message" },
  },
  opts = {
    adapters = {
      http = {
        ollama = function()
          return require("codecompanion.adapters").extend("ollama", {
            schema = {
              model = { default = "qwen3:8b" },
              think = { default = false },
              keep_alive = { default = "30m" },
            },
          })
        end,
      },
    },
    interactions = {
      chat = { adapter = "ollama" },
      inline = { adapter = "ollama" },
    },
    prompt_library = {
      markdown = {
        dirs = { vim.fn.stdpath("config") .. "/prompts" },
      },
    },
    opts = {
      language = "the same language the user writes in",
    },
    display = {
      chat = { show_settings = true },
    },
  },
}
