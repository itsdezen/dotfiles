-- Colours: Nord (repo-wide unified theme, see AGENTS.md rule 6).
require("nord").setup({
  transparent = true,
  on_highlights = function(highlights, colors)
    highlights.WinSeparator = { fg = colors.polar_night.brightest, bold = true }
    highlights.LineNr = { fg = colors.polar_night.light }
    highlights.LineNrAbove = { fg = colors.polar_night.light }
    highlights.LineNrBelow = { fg = colors.polar_night.light }
    -- nord.nvim's `transparent` only clears Normal/SignColumn; floats and
    -- non-current windows need explicit overrides
    highlights.NormalFloat = { fg = colors.snow_storm.origin, bg = colors.none }
    highlights.FloatBorder = { fg = colors.polar_night.brightest, bg = colors.none }
    highlights.WhichKeyFloat = { bg = colors.none }
    highlights.NormalNC = { fg = colors.snow_storm.origin, bg = colors.none }
  end,
})
vim.cmd.colorscheme("nord")

-- Icons: needed by lualine and snacks right away.
require("mini.icons").setup()
require("mini.icons").mock_nvim_web_devicons()

-- Statusline: visible from the first frame.
require("lualine").setup({
  options = {
    theme = "auto",
    globalstatus = true,
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch" },
    lualine_c = {
      { "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = " " } },
      { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
      { "filename", path = 1 },
    },
    lualine_x = {
      {
        "diff",
        symbols = { added = " ", modified = " ", removed = " " },
        source = function()
          local gitsigns = vim.b.gitsigns_status_dict
          if gitsigns then
            return { added = gitsigns.added, modified = gitsigns.changed, removed = gitsigns.removed }
          end
        end,
      },
    },
    lualine_y = {
      { "progress", separator = " ", padding = { left = 1, right = 0 } },
      { "location", padding = { left = 0, right = 1 } },
    },
    lualine_z = {
      function() return " " .. os.date("%R") end,
    },
  },
})

-- Keymap hints: must answer the leader key immediately. Without these names
-- which-key falls back to "+N keymaps" for every prefix.
require("which-key").setup({
  preset = "helix",
  spec = {
    { "<leader>b", group = "buffer", mode = { "n", "x" } },
    { "<leader>c", group = "code", mode = { "n", "x" } },
    { "<leader>d", group = "diff", mode = { "n", "x" } },
    { "<leader>f", group = "file/find", mode = { "n", "x" } },
    { "<leader>g", group = "git", mode = { "n", "x" } },
    { "<leader>gh", group = "hunks", mode = { "n", "x" } },
    { "<leader>q", group = "quit", mode = { "n", "x" } },
    { "<leader>s", group = "search", mode = { "n", "x" } },
    { "<leader>u", group = "ui", mode = { "n", "x" } },
    { "<leader>w", group = "windows", mode = { "n", "x" } },
    { "<leader>x", group = "diagnostics/quickfix", mode = { "n", "x" } },
    { "g", group = "goto", mode = { "n", "x" } },
    { "[", group = "prev", mode = { "n", "x" } },
    { "]", group = "next", mode = { "n", "x" } },
    { "z", group = "fold", mode = { "n", "x" } },
  },
})

-- Snacks provides the file explorer, the pickers, the notifications and the
-- floating terminal. Every module listed here is opt-in: dropping a key turns
-- that module off (that is how the dashboard was removed).
require("snacks").setup({
  explorer = { replace_netrw = true },
  indent = { chunk = { enabled = true } },
  input = {},
  notifier = {},
  picker = {
    sources = {
      explorer = {
        hidden = true,
        ignored = true,
        layout = { preview = "main", layout = { preset = "sidebar" } },
      },
      files = {
        hidden = true,
        ignored = false,
      },
    },
  },
  words = {},
  terminal = {
    win = { position = "float", border = "rounded" },
  },
  image = {
    backend = "kitty",
  },
})
