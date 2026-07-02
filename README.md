# dotfiles

Personal macOS development environment using **GNU Stow** for dotfiles management.

## Stack

- 🍺 **Homebrew** — package management
- 🐚 **zsh + zinit + Starship** — shell, plugins, prompt
- 🔧 **mise** — polyglot runtime manager (node, bun, python, rust, go)
- 📦 **pnpm + bun** — JS package managers
- ✏️ **Neovim (LazyVim)** — terminal editor
- ⚡ **Zed** — primary code editor (Claude AI built-in)
- 👻 **Ghostty** — GPU-accelerated terminal emulator (managed by cmux)
- 🖥️ **cmux** — terminal multiplexer built on top of Ghostty
- 📟 **tmux** — terminal multiplexer for session management
- 🪟 **AeroSpace** — i3-like tiling window manager
- 🤖 **Ollama** — local LLM inference (Qwen3 8B)
- 📁 **superfile** — terminal file manager (Nord theme)
- 📊 **btop** — resource monitor (CPU, memory, disks, network, processes)

## Quick Start

```bash
git clone https://github.com/itsdezen/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles && ./sync.sh
```

`sync.sh` is idempotent — run it on a fresh machine or anytime to sync/update.

## Scripts

| Script | Description |
|--------|-------------|
| `./sync.sh` | Sync everything: Homebrew, dotfiles, runtimes, nvim plugins |
| `./sync.sh uninstall` | Remove all dotfiles symlinks and zinit |

## Stow Packages

| Package | Symlinks to |
|---------|-------------|
| `zsh` | `~/.zshrc`, `~/.zshenv`, `~/.zprofile` |
| `nvim` | `~/.config/nvim/` |
| `aerospace` | `~/.config/aerospace/` |
| `starship` | `~/.config/starship.toml` |
| `zed` | `~/.config/zed/` |
| `ghostty` | `~/.config/ghostty/` |
| `cmux` | `~/.config/cmux/` |
| `tmux` | `~/.tmux.conf` |
| `mise` | `~/.config/mise/config.toml` |
| `git` | `~/.gitconfig` |
| `ollama` | `~/.config/ollama/env` |
| `superfile` | `~/.config/superfile/` |
| `btop` | `~/.config/btop/` |

## Runtimes (mise)

```toml
node = "lts"
bun = "latest"
python = "latest"
rust = "latest"
go = "latest"
```

## Key Bindings

### AeroSpace

| Key | Action |
|-----|--------|
| `alt-hjkl` | Focus window |
| `alt-shift-hjkl` | Move window |
| `alt-w/e/1/2/3` | Switch workspace |
| `alt-shift-w/e/1/2/3` | Move to workspace |
| `alt-/` | Toggle tiles layout |
| `alt-,` | Toggle accordion layout |

Workspaces: **work** (Zed + Ghostty, auto-assigned), **entertain**, **1/2/3**.

### Neovim

LazyVim defaults. Custom: `kanagawa-dragon` colorscheme (transparent), biome formatter (JS/TS/CSS/JSON), snacks.nvim picker.

## Key Config Details

### nvim (`nvim/.config/nvim/lua/`)

- **Colorscheme**: `kanagawa-dragon` + transparent (`plugins/colorscheme.lua`)
- **LazyVim extras**: `coding.blink`, `lang.typescript`, `lang.tailwind`, `lang.python`, `lang.rust`, `lang.go`, `lang.vue`, `lang.svelte`
- **Formatting**: `conform.nvim` — biome → prettier fallback (JS/TS/JSX/TSX/JSON/CSS), prettier (Vue/Svelte), stylua (Lua), goimports/gofumpt (Go, via `lang.go` extra), ruff/rustfmt via LSP fallback (Python/Rust)
- **UI**: lualine (powerline separators), bufferline (slant), snacks.indent (chunk scope), noice.nvim (default on), nvim-colorizer
- **Disabled**: catppuccin (`plugins/disabled.lua`)

### zed (`zed/.config/zed/`)

- **Theme**: Tokyo Night (dark) / Tokyo Night Day (light)
- **Font**: Maple Mono NF, size 14, ligatures on
- **AI**: Claude Sonnet via anthropic provider, claude-acp MCP server

### ghostty (`ghostty/.config/ghostty/config`)

- **Font**: Maple Mono NF, size 12
- **Theme**: `kanagawa-dragon` (built-in), opacity 0.7, blur on
- Config is required by cmux (which runs on top of Ghostty)

### cmux (`cmux/.config/cmux/cmux.json`)

- **Mode**: minimal mode enabled
- **Quit**: confirm always
- Sections for terminal, sidebar, notifications, shortcuts, automation are available as commented-out JSONC blocks

### tmux (`tmux/.tmux.conf`)

- **Prefix**: `C-a`
- **Mouse**: enabled
- **Splits**: `|` horizontal, `-` vertical (opens in current path)
- **Pane nav**: `prefix + h/j/k/l`
- **Reload**: `prefix + r`

### superfile (`superfile/.config/superfile/`)

- **Theme**: `nord` (`config.toml` → `theme = "nord"`, definition in `theme/nord.toml`)
- Launch with `spf`

### btop (`btop/.config/btop/btop.conf`)

- **Background**: `theme_background = false` for terminal transparency
- **Theme**: `kanagawa-dragon` (`btop/.config/btop/themes/kanagawa-dragon.theme`) — matches nvim/Ghostty colorscheme

### ollama (`ollama/.config/ollama/env`)

- **Host**: `127.0.0.1:11434`
- **Keep alive**: `5m` (model stays loaded for 5 minutes after last request)
- **Flash attention**: enabled
- **Models**: stored at `~/.ollama/models` — not versioned in dotfiles
- Default model: `qwen3:8b` (pulled automatically by `sync.sh`)

### zsh (`zsh/.zshrc`)

- Plugin manager: zinit (turbo/lazy)
- Plugins: git (oh-my-zsh), zsh-autosuggestions, fast-syntax-highlighting
- `EDITOR` = `code --wait`
- Sources `~/.zshrc.local` if present (machine-specific overrides, not committed)

## Workflow

```bash
# Edit → commit → push
nvim zsh/.zshrc
git add . && git commit -m "🔧 ..." && git push

# Pull and sync on another machine
git pull && ./sync.sh
```

## Troubleshooting

**Stow conflict** — `sync.sh` resolves automatically (dotfiles win, no backups).

```bash
./sync.sh        # re-run to fix
./stow-install.sh restow   # or restow manually
```
