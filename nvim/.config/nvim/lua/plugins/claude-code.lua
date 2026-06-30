return {
  "greggh/claude-code.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "ClaudeCode", "ClaudeCodeContinue", "ClaudeCodeResume", "ClaudeCodeVerbose" },
  keys = {
    { "<C-,>", desc = "Toggle Claude Code" },
    { "<leader>cC", desc = "Claude Code: continue" },
    { "<leader>cV", desc = "Claude Code: verbose" },
  },
  config = function()
    require("claude-code").setup({
      window = {
        position = "botright vertical",
        split_ratio = 0.3,
      },
    })
  end,
}
