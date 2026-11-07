local pack = require("config.pack")

-- Completion. Also an entrypoint: its plugin/ script sets the global LSP
-- capabilities, which we would otherwise have to declare by hand.
--
-- The capabilities must exist before any LSP client attaches, so the setup
-- runs eagerly; only blink's own runtime is deferred.
pack.eager("blink.cmp", function()
  require("blink.cmp").setup({
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
    },
    cmdline = {
      enabled = true,
      keymap = { preset = "cmdline", ["<Right>"] = false, ["<Left>"] = false },
      completion = {
        list = { selection = { preselect = false } },
        menu = {
          auto_show = function(ctx) return vim.fn.getcmdtype() == ":" end,
        },
      },
    },
    keymap = { preset = "enter", ["<C-y>"] = { "select_and_accept" } },
  })
end)

-- Auto-pairing.
pack.eager("mini.pairs", function()
  require("mini.pairs").setup({
    modes = { insert = true, command = true, terminal = false },
  })
end)

-- TODO highlighting.
pack.eager("todo-comments", function()
  require("todo-comments").setup()
end)

-- Formatting (on save and on demand).
pack.eager("conform", function()
  require("conform").setup({
    default_format_opts = {
      timeout_ms = 3000,
      async = false,
      quiet = false,
      lsp_format = "fallback",
    },
    format_on_save = function(bufnr)
      if vim.g.autoformat == false or vim.b[bufnr].autoformat == false then
        return
      end
      return { timeout_ms = 3000, lsp_format = "fallback" }
    end,
    formatters_by_ft = {
      lua = { "stylua" },
      fish = { "fish_indent" },
      sh = { "shfmt" },
      javascript = { "biome-check", "prettier", stop_after_first = true },
      javascriptreact = { "biome-check", "prettier", stop_after_first = true },
      typescript = { "biome-check", "prettier", stop_after_first = true },
      typescriptreact = { "biome-check", "prettier", stop_after_first = true },
      json = { "biome-check", "prettier", stop_after_first = true },
      css = { "biome-check", "prettier", stop_after_first = true },
      vue = { "prettier" },
      svelte = { "prettier" },
      python = { "ruff_format" },
      go = { "goimports", "gofumpt" },
      rust = { "rustfmt" },
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
  })
end)

-- Git signs.
pack.eager("gitsigns", function()
  require("gitsigns").setup({
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
      untracked = { text = "▎" },
    },
    signs_staged = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
      untracked = { text = "▎" },
    },
    on_attach = function(buffer)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc, silent = true })
      end

      map("n", "]h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gs.nav_hunk("next")
        end
      end, "Next hunk")
      map("n", "[h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gs.nav_hunk("prev")
        end
      end, "Prev hunk")
      map("n", "]H", function() gs.nav_hunk("last") end, "Last hunk")
      map("n", "[H", function() gs.nav_hunk("first") end, "First hunk")
      map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage hunk")
      map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset hunk")
      map({ "n", "x" }, "<leader>ghS", gs.stage_buffer, "Stage buffer")
      map({ "n", "x" }, "<leader>ghu", gs.undo_stage_hunk, "Undo stage hunk")
      map({ "n", "x" }, "<leader>ghR", gs.reset_buffer, "Reset buffer")
      map({ "n", "x" }, "<leader>ghp", gs.preview_hunk_inline, "Preview hunk inline")
      map({ "n", "x" }, "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame line")
      map({ "n", "x" }, "<leader>ghB", function() gs.blame() end, "Blame buffer")
      map({ "n", "x" }, "<leader>ghd", gs.diffthis, "Diff this")
      map({ "n", "x" }, "<leader>ghD", function() gs.diffthis("~") end, "Diff this ~")
      map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Gitsigns select hunk")
    end,
  })
end)

-- Search and replace across files.
pack.eager("grug-far", function()
  require("grug-far").setup({})
end)

-- Open the real file when jumping into a dependency.
pack.eager("gitlinker", function()
  require("gitlinker").setup()
end)
