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
    disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" } },
    refresh = {
      events = {
        "WinEnter",
        "BufEnter",
        "BufWritePost",
        "SessionLoadPost",
        "FileChangedShellPost",
        "VimResized",
        "Filetype",
        "CursorMoved",
        "CursorMovedI",
        "ModeChanged",
      },
    },
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

-- Keymap hints: must answer the leader key immediately.
require("which-key").setup({
  preset = "helix",
  spec = {
    {
      mode = { "n", "x" },
      { "<leader><tab>", group = "tabs" },
      { "<leader>c", group = "code" },
      { "<leader>f", group = "file/find" },
      { "<leader>g", group = "git" },
      { "<leader>gh", group = "hunks" },
      { "<leader>q", group = "quit/session" },
      { "<leader>s", group = "search" },
      { "<leader>u", group = "ui" },
      { "<leader>x", group = "diagnostics/quickfix" },
      { "[", group = "prev" },
      { "]", group = "next" },
      { "g", group = "goto" },
      { "gs", group = "surround" },
      { "z", group = "fold" },
      { "<leader>b", group = "buffer" },
      { "<leader>w", group = "windows", proxy = "<c-w>" },
    },
  },
})

-- Snacks provides the file explorer, the pickers, the notifications and the
-- dashboard.
require("snacks").setup({
  -- listing a module key here (even empty) is enough to enable it
  dashboard = {
    -- No "startup" section: it reads `lazy.stats`, which only exists with
    -- lazy.nvim. This config uses Neovim's built-in `vim.pack`.
    sections = {
      { section = "header" },
      { section = "keys", gap = 1, padding = 1 },
    },
    preset = {
      header = [[
██████╗ ███████╗███████╗███████╗███╗   ██╗
██╔══██╗██╔════╝╚══███╔╝██╔════╝████╗  ██║
██║  ██║█████╗    ███╔╝ █████╗  ██╔██╗ ██║
██║  ██║██╔══╝   ███╔╝  ██╔══╝  ██║╚██╗██║
██████╔╝███████╗███████╗███████╗██║ ╚████║
╚═════╝ ╚══════╝╚══════╝╚══════╝╚═╝  ╚═══╝]],
      keys = {
        { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
        { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
        { icon = "󰒲 ", key = "h", desc = "Help", action = ":checkhealth" },
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
  },
  explorer = { replace_netrw = true },
  indent = {
    chunk = {
      enabled = true,
      char = {
        corner_top = "╭",
        corner_bottom = "╰",
        arrow = "›",
      },
    },
    animate = {
      duration = { total = 300 },
    },
  },
  input = {},
  notifier = {},
  picker = {
    icons = {
      tree = {
        vertical = "│ ",
        middle = "├╴",
        last = "╰╴",
      },
    },
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
  quickfile = {},
  scope = {},
  scroll = {},
  -- NOTE: statuscolumn is disabled on purpose. It reads
  -- `vim.g.statusline_winid`, which Neovim only sets while evaluating
  -- 'statusline' -- never for 'statuscolumn' -- so the expression errors
  -- out and the column stays empty.
  statuscolumn = { enabled = false },
  words = {},
  terminal = {
    win = { position = "float", border = "rounded" },
  },
  image = {
    backend = "kitty",
  },
  styles = {
    notification = { border = "rounded" },
  },
})

-- Trouble: diagnostics / symbols / TODO panels.
require("trouble").setup()

-- Floating cmdline, positioned by the native ui2 system.
require("tiny-cmdline").setup({
  width = { value = "70%" },
  position = { y = "20%" },
})

