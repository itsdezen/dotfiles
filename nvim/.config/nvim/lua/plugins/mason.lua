-- Language servers and the formatters only Neovim calls live here; mise owns
-- runtimes and the CLIs a shell (or an agent) calls directly. Splitting it that
-- way keeps every tool on one owner: nothing below is installed by mise, and
-- nothing in mise/config.toml is installed here. The dual-use servers
-- (ruff, basedpyright, gopls) stay in mise precisely because the shell uses them
-- too — mason's bin dir is not on the shell's PATH.
--
-- mason.setup() prepends its bin dir to vim.env.PATH, so these binaries resolve
-- inside Neovim without touching the shell's PATH. `sync.sh` pre-provisions the
-- list with `MasonToolsInstallSync`; run_on_start covers a machine that pulled
-- the repo but has not synced yet (LSP attaches on FileType, before VimEnter,
-- so the very first file of a fresh install may need a reopen).
require("mason").setup()

require("mason-tool-installer").setup({
  ensure_installed = {
    "lua-language-server",
    "vtsls",
    "bash-language-server",
    "rust-analyzer",
    -- Common formats: the binaries below only Neovim needs.
    "json-lsp",
    "css-lsp",
    "html-lsp",
    "yaml-language-server",
    "tailwindcss-language-server",
    "eslint-lsp",
    "marksman",
    "dockerfile-language-server",
    -- Formatters conform calls, plus the parser CLI nvim-treesitter builds with.
    -- Pinned by the registry, so a format can't drift with a `mise upgrade`.
    "prettier",
    "prettierd",
    "stylua",
    "shfmt",
    "gofumpt",
    "goimports",
    "tree-sitter-cli",
  },
  auto_update = false,
  run_on_start = true,
})
