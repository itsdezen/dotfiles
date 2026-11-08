local opt = vim.opt

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Behaviour
opt.autowrite = true
opt.breakindent = true
opt.confirm = true
opt.cursorline = true
opt.expandtab = true
opt.linebreak = true
opt.list = true
opt.mouse = "a"
opt.number = true
opt.relativenumber = true
opt.ruler = false
opt.scrolloff = 4
opt.shiftround = true
opt.shiftwidth = 2
opt.shortmess:append({ W = true, I = true, c = true })
opt.showmode = false
opt.sidescrolloff = 8
opt.smartcase = true
opt.smartindent = true
opt.smoothscroll = true
opt.splitbelow = true
opt.splitkeep = "screen"
opt.splitright = true
opt.tabstop = 2
opt.termguicolors = true
opt.timeoutlen = 300
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 200
opt.virtualedit = "block"
opt.winminwidth = 5
opt.wrap = false

-- Completion (native `vim.lsp.completion`; no plugin).
-- "fuzzy" is fuzzy matching, "popup" shows the completionItem/resolve docs.
opt.completeopt = "menuone,noselect,fuzzy,popup"
opt.pumblend = 10
opt.pumheight = 10

-- Display
opt.cmdheight = 0
opt.conceallevel = 2
opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
opt.foldlevel = 99
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""
opt.formatoptions = "jcroqlnt"
-- Nvim's default grepprg already uses rg, but with -uu (hidden + ignored files).
-- Drop -uu so :grep stays out of node_modules and .git.
opt.grepprg = "rg --vimgrep"
opt.ignorecase = true
opt.laststatus = 3
opt.matchtime = 2
opt.showmatch = true
opt.signcolumn = "yes"
opt.winborder = "rounded"

-- Files
opt.clipboard = vim.env.SSH_CONNECTION and "" or "unnamedplus"
opt.undodir = vim.fn.expand("~/.cache/nvim/undodir")
opt.writebackup = false
opt.swapfile = false

-- Word motions: treat `-` as part of a word (kebab-case in TS/CSS)
opt.iskeyword:append("-")

-- Searching
opt.path:append("**")
opt.wildignore:append({
  "*/node_modules/*",
  "*.o",
  "*.obj",
  "*.pyc",
  "*.class",
  "*.jar",
})

-- Cursor
opt.guicursor =
  "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"

-- Neovim 0.12 native floating cmdline + message windows.
--
-- `ui2.enable()` returns early when no UI is attached yet (it needs the TUI to
-- be up), so it is called from VimEnter instead of during startup.
--
-- `msg.target = "msg"` is required: with `cmdheight = 0` the cmdline window is
-- hidden, so messages routed there would be invisible. Everything else falls
-- back to the `[""]` entry.
local ui2_opts = {
  enable = true,
  msg = {
    target = "msg",
    targets = {
      [""] = "msg",
      emsg = "pager",
      search_cmd = "msg",
      shell_cmd = "pager",
      shell_err = "pager",
      shell_out = "pager",
    },
    cmd = { height = 0.5 },
    dialog = { height = 0.5 },
    msg = { height = 0.3, timeout = 4000 },
    pager = { height = 0.5 },
  },
}

vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("Ui2", { clear = true }),
  callback = function()
    require("vim._core.ui2").enable(ui2_opts)
  end,
})

-- ui2 renders its buffers as full-width, borderless strips glued to
-- 'laststatus'. Turn the cmdline into a centered rounded box at the top of the
-- editor. Every other float already inherits 'winborder' (= rounded) or passes
-- "rounded" itself: LSP floats, snacks, which-key, codediff, gitsigns and the
-- ui2 message window (border = nil -> 'winborder').
-- ui2 only changes hide/height after creation, so this geometry persists.
local ui2_group = vim.api.nvim_create_augroup("Ui2Floats", { clear = true })

local function style_cmdline(win)
  if not win or win <= 0 or not vim.api.nvim_win_is_valid(win) then return end
  if vim.api.nvim_win_get_config(win).relative == "" then return end

  -- Compact: ~half the screen, capped at 60 columns.
  local width = math.min(60, math.max(30, math.floor(vim.o.columns * 0.5)))
  vim.api.nvim_win_set_config(win, {
    border = "rounded",
    width = width,
    relative = "editor",
    anchor = "NW",
    -- ~10% from the top (at least 2 lines) so it doesn't hug the edge.
    row = math.max(2, math.floor(vim.o.lines * 0.1)),
    col = math.floor((vim.o.columns - width) / 2),
  })
end

vim.api.nvim_create_autocmd("FileType", {
  group = ui2_group,
  pattern = "cmd",
  callback = function()
    style_cmdline(vim.api.nvim_get_current_win())
  end,
})

vim.api.nvim_create_autocmd("VimResized", {
  group = ui2_group,
  callback = function()
    local ui = package.loaded["vim._core.ui2"]
    if ui then style_cmdline(ui.wins.cmd) end
  end,
})

vim.diagnostic.config({
  virtual_text = {
    spacing = 4,
    source = "if_many",
    prefix = "●",
  },
  severity_sort = true,
  -- No border here: floats inherit 'winborder'.
  float = {
    source = "if_many",
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅙",
      [vim.diagnostic.severity.WARN] = "󰀨",
      [vim.diagnostic.severity.HINT] = "󰋗",
      [vim.diagnostic.severity.INFO] = "󰋼",
    },
  },
})
