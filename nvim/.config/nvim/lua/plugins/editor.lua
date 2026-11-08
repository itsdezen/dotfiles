-- Formatting: on demand only. Format-on-save is off on purpose -- it rewrites
-- the files an agent just wrote and scrambles the diff being reviewed.
require("conform").setup({
  default_format_opts = {
    timeout_ms = 3000,
    async = true,
    lsp_format = "fallback",
  },
  formatters_by_ft = {
    lua = { "stylua" },
    fish = { "fish_indent" },
    sh = { "shfmt" },
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
    json = { "prettier" },
    css = { "prettier" },
    vue = { "prettier" },
    svelte = { "prettier" },
    python = { "ruff_format" },
    go = { "goimports", "gofumpt" },
    rust = { "rustfmt" },
  },
})

-- Git signs + hunk navigation. The maps are buffer-local so they only exist in
-- buffers gitsigns actually tracks.
require("gitsigns").setup({
  on_attach = function(buffer)
    local gs = package.loaded.gitsigns

    local function map(mode, l, r, desc)
      vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc, silent = true })
    end

    map("n", "]h", function() gs.nav_hunk("next") end, "Next hunk")
    map("n", "[h", function() gs.nav_hunk("prev") end, "Prev hunk")
    map("n", "]H", function() gs.nav_hunk("last") end, "Last hunk")
    map("n", "[H", function() gs.nav_hunk("first") end, "First hunk")
    map({ "n", "x" }, "<leader>ghs", "<cmd>Gitsigns stage_hunk<cr>", "Stage hunk")
    map({ "n", "x" }, "<leader>ghr", "<cmd>Gitsigns reset_hunk<cr>", "Reset hunk")
    map("n", "<leader>ghS", gs.stage_buffer, "Stage buffer")
    map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview hunk inline")
    map("n", "<leader>ghd", gs.diffthis, "Diff this")
  end,
})

-- Side-by-side diff viewer: `:CodeDiff`, `:CodeDiff history %`, `:CodeDiff history`.
require("codediff").setup()
