local opt = vim.opt

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.autoformat = true

-- Behaviour
opt.autowrite = true
opt.breakindent = true
opt.confirm = true
opt.cursorline = true
opt.expandtab = true
opt.inccommand = "nosplit"
opt.jumpoptions = "view"
opt.linebreak = true
opt.list = true
opt.mouse = "a"
opt.number = true
opt.relativenumber = true
opt.ruler = false
opt.scrolloff = 4
opt.shiftround = true
opt.shiftwidth = 2
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.showmode = false
opt.sidescrolloff = 8
opt.smartcase = true
opt.smartindent = true
opt.smoothscroll = true
opt.spelllang = { "en" }
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
opt.wildmode = "longest:full,full"
opt.winminwidth = 5
opt.wrap = false

-- Completion
opt.completeopt = "menu,menuone,noinsert,noselect"
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
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"
opt.ignorecase = true
opt.laststatus = 3
opt.matchtime = 2
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
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
-- hidden, so messages routed there would be invisible.
-- `msg.targets` is a per-kind table (kind -> "cmd" | "msg" | "pager").
local ui2_opts = {
  enable = true,
  msg = {
    target = "msg",
    targets = {
      [""] = "msg",
      empty = "cmd",
      bufwrite = "msg",
      confirm = "cmd",
      emsg = "pager",
      echo = "msg",
      echomsg = "msg",
      echoerr = "pager",
      completion = "cmd",
      list_cmd = "pager",
      lua_error = "pager",
      lua_print = "msg",
      progress = "pager",
      rpc_error = "pager",
      quickfix = "msg",
      search_cmd = "msg",
      search_count = "msg",
      shell_cmd = "pager",
      shell_err = "pager",
      shell_out = "pager",
      shell_ret = "msg",
      undo = "msg",
      verbose = "pager",
      wildlist = "msg",
      wmsg = "msg",
      typed_cmd = "cmd",
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

-- Snacks' dashboard takes over the whole screen and resets 'laststatus' to 0
-- while it is open. It restores the previous value on close, but it captures
-- that value when it opens -- which happens before lualine sets 'laststatus'
-- to 3 for the global statusline. The result is a missing statusline.
--
-- Re-apply it once the dashboard is gone.
vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("Statusline", { clear = true }),
  pattern = "SnacksDashboardClosed",
  callback = function()
    vim.o.laststatus = 3
  end,
})
vim.diagnostic.config({
  underline = true,
  update_in_insert = false,
  virtual_text = {
    spacing = 4,
    source = "if_many",
    prefix = "●",
  },
  severity_sort = true,
  float = {
    border = "rounded",
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
