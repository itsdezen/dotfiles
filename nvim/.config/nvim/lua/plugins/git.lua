return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff View" },
      { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Diff View Close" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "File History" },
    },
  },
  {
    "akinsho/git-conflict.nvim",
    event = "BufReadPre",
    config = true,
  },
}
