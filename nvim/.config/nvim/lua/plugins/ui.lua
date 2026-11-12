-- Colours: Gruvbox (repo-wide unified theme, see AGENTS.md rule 6).
local palette = require("gruvbox").palette

require("gruvbox").setup({
  contrast = "",
  transparent_mode = true,
  overrides = {
    -- gruvbox.nvim's `transparent_mode` only clears Normal/NormalFloat/
    -- SignColumn/FoldColumn/WinSeparator; float borders and the tabline row
    -- are still painted, so reset their background explicitly.
    WinSeparator = { fg = palette.dark4, bg = "NONE", bold = true },
    FloatBorder = { fg = palette.dark4, bg = "NONE" },
    WhichKeyFloat = { bg = "NONE" },
    -- The whole tabline row is painted with TabLineFill; clear its bg or the
    -- bufferline gets an opaque strip. TabLineSel only feeds bufferline's
    -- selected-indicator colour (no background is painted from it).
    TabLineFill = { bg = "NONE" },
    TabLineSel = { fg = palette.bright_yellow, bg = "NONE" },
  },
})
vim.cmd.colorscheme("gruvbox")

-- Icons: needed by lualine and snacks right away.
require("mini.icons").setup()
require("mini.icons").mock_nvim_web_devicons()

--- Nerd Font glyph by codepoint (LuaJIT has no \u{...} escape).
local function glyph(hex) return vim.fn.nr2char(tonumber(hex, 16)) end
local gh_icon = glyph("f408") .. " "

-- Bufferline: the tabline is hidden while there is nothing to switch between
-- (`always_show_bufferline = false`), and the offset keeps the tabs clear of the
-- explorer sidebar. Colours are derived from the transparent Gruvbox groups.
require("bufferline").setup({
  options = {
    close_command = function(n) Snacks.bufdelete(n) end,
    right_mouse_command = function(n) Snacks.bufdelete(n) end,
    diagnostics = "nvim_lsp",
    always_show_bufferline = false,
    diagnostics_indicator = function(_, _, diag)
      local icons = { Error = glyph("f057") .. " ", Warn = glyph("f071") .. " " }
      local ret = (diag.error and icons.Error .. diag.error .. " " or "")
        .. (diag.warning and icons.Warn .. diag.warning or "")
      return vim.trim(ret)
    end,
    offsets = {
      { filetype = "neo-tree", text = "Neo-tree", highlight = "Directory", text_align = "left" },
      { filetype = "snacks_layout_box" },
    },
    get_element_icon = function(opts)
      return ({ octo = gh_icon, gh = gh_icon, ["markdown.gh"] = gh_icon })[opts.filetype]
    end,
  },
})

-- Restored sessions add buffers before bufferline is up; refresh once they land.
vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
  group = vim.api.nvim_create_augroup("BufferLineRefresh", { clear = true }),
  callback = function()
    vim.schedule(function() pcall(nvim_bufferline) end)
  end,
})

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
  scroll = {},
  words = {},
  terminal = {
    win = { position = "float", border = "rounded" },
  },
  image = {
    backend = "kitty",
  },
})
