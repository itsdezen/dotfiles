# dotfiles

Personal macOS development environment using **GNU Stow** for dotfiles management.

## Stack

- 🍺 **Homebrew** — package management
- 🐚 **zsh + zinit + Starship** — shell, plugins, prompt
- 🔧 **mise** — polyglot runtime manager (node, bun, python, rust, go)
- 📦 **pnpm + bun** — JS package managers
- ✏️ **Neovim (LazyVim)** — terminal editor
- ⚡ **Zed** — primary code editor (Claude AI built-in)
- 🖥️ **cmux** — Ghostty-based terminal
- 🪟 **AeroSpace** — i3-like tiling window manager

## Quick Start

```bash
git clone https://github.com/onepercman/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles && ./sync.sh
```

`sync.sh` is idempotent — run it on a fresh machine or anytime to sync/update.

## Scripts

| Script | Description |
|--------|-------------|
| `./sync.sh` | Sync everything: Homebrew, dotfiles, runtimes, nvim plugins |
| `./stow-install.sh [install\|restow\|remove\|list]` | Manual stow operations |
| `./uninstall.sh` | Remove dotfiles and zinit |

## Stow Packages

| Package | Symlinks to |
|---------|-------------|
| `zsh` | `~/.zshrc`, `~/.zshenv`, `~/.zprofile` |
| `nvim` | `~/.config/nvim/` |
| `aerospace` | `~/.config/aerospace/` |
| `starship` | `~/.config/starship.toml` |
| `zed` | `~/.config/zed/` |
| `cmux` | `~/.config/cmux/` |
| `ghostty` | `~/.config/ghostty/` |
| `mise` | `~/.config/mise/config.toml` |

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

Workspaces: **work** (Zed + cmux, auto-assigned), **entertain**, **1/2/3**.

### Neovim

LazyVim defaults. Custom: `tokyonight` colorscheme (transparent), biome formatter (JS/TS/CSS/JSON), snacks.nvim picker.

## Key Config Details

### nvim (`nvim/.config/nvim/lua/`)

- **Colorscheme**: `tokyonight` + transparent (`plugins/colorscheme.lua`)
- **LazyVim extras**: `coding.blink`, `lang.typescript`, `lang.tailwind`
- **Formatting**: `conform.nvim` — biome (JS/TS/JSX/TSX/JSON/CSS), stylua (Lua)
- **UI**: lualine (powerline separators), bufferline (slant), snacks.indent (chunk scope), noice.nvim (default on), nvim-colorizer
- **Disabled**: catppuccin (`plugins/disabled.lua`)

### zed (`zed/.config/zed/`)

- **Theme**: Tokyo Night (dark) / Tokyo Night Day (light)
- **Font**: MapleMono NF, size 14, ligatures on
- **AI**: Claude Sonnet via anthropic provider, claude-acp MCP server

### ghostty (`ghostty/.config/ghostty/config`)

- **Font**: MapleMono NF, size 12
- **Theme**: `TokyoNight` (built-in), opacity 0.7, blur on

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
