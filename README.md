# dotfiles

Personal macOS development environment using **GNU Stow** for dotfiles management.

## Stack

- 🍺 **Homebrew** — package management
- 🐚 **zsh + zinit + Starship** — shell, plugins, prompt
- 🔧 **mise** — polyglot runtime manager (node, bun, pnpm, python, uv, rust, go)
- 📦 **pnpm + bun** — JS package managers
- ✏️ **Neovim (LazyVim)** — primary code editor
- 👻 **Ghostty** — GPU-accelerated terminal emulator (managed by cmux)
- 🖥️ **cmux** — terminal multiplexer built on top of Ghostty
- 🪟 **AeroSpace** — i3-like tiling window manager
- 🔨 **Hammerspoon** — macOS automation via Lua
- 🤖 **Ollama** — local LLM inference (Qwen3 8B)
- 🐙 **lazygit** — terminal UI for git, standalone or inside Neovim (`<leader>gg`)
- 📁 **superfile** — terminal file manager (Kanagawa Dragon theme)
- 📊 **btop** — resource monitor (CPU, memory, disks, network, processes)

## Quick Start

**Fresh machine** (installs Xcode CLI tools, clones repo, runs sync):
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/itsdezen/dotfiles/main/sync.sh) bootstrap
```

**Existing machine:**
```bash
git clone https://github.com/itsdezen/dotfiles ~/Developer/dotfiles
cd ~/Developer/dotfiles && ./sync.sh
```

`sync.sh` is idempotent — safe to re-run anytime to sync/update.

## Scripts

| Script | Description |
|--------|-------------|
| `./sync.sh` | Sync everything: Homebrew, dotfiles, runtimes, nvim plugins |
| `./sync.sh bootstrap` | Fresh machine setup: Xcode CLI tools → clone → sync |
| `./sync.sh uninstall` | Remove all dotfiles symlinks and zinit |

## Stow Packages

| Package | Symlinks to |
|---------|-------------|
| `zsh` | `~/.zshrc`, `~/.zshenv`, `~/.zprofile` |
| `nvim` | `~/.config/nvim/` |
| `aerospace` | `~/.config/aerospace/` |
| `hammerspoon` | `~/.hammerspoon/` |
| `starship` | `~/.config/starship.toml` |
| `ghostty` | `~/.config/ghostty/` |
| `cmux` | `~/.config/cmux/` |
| `mise` | `~/.config/mise/config.toml` |
| `fastfetch` | `~/.config/fastfetch/` |
| `git` | `~/.gitconfig` |
| `ollama` | `~/.config/ollama/env` |
| `superfile` | `~/.config/superfile/` |
| `btop` | `~/.config/btop/` |
| `lazygit` | `~/.config/lazygit/` |
| `claude` | `~/.claude/settings.json` |

## Runtimes (mise)

```toml
# JavaScript / Bun
node = "lts"
bun = "latest"
pnpm = "latest"

# Python
python = "latest"
uv = "latest"

# Systems
rust = "latest"
go = "latest"
```

## Key Bindings

### AeroSpace

| Key | Action |
|-----|--------|
| `alt-hjkl` | Focus window |
| `alt-shift-hjkl` | Move window |
| `alt-w/e/r` | Switch workspace |
| `alt-shift-w/e/r` | Move to workspace |
| `alt-/` | Toggle tiles layout |
| `alt-,` | Toggle accordion layout |

Workspaces: **work** (Zed + cmux, auto-assigned), **entertain**, **random** (catch-all).

### Neovim

LazyVim defaults. Custom: `kanagawa-dragon` colorscheme (transparent), biome formatter (JS/TS/CSS/JSON), snacks.nvim picker. `<leader>gg` opens lazygit in a float (root dir), `<leader>gG` for cwd.

## Highlights

- **Unified theme** — Kanagawa Dragon across nvim, Ghostty, Zed, btop, and lazygit for a consistent look everywhere
- **AI-native editing** — Zed ships with Claude built-in; Ollama runs local models as an offline fallback
- **Keyboard-driven window management** — AeroSpace tiling + Hammerspoon Lua automation
- **Terminal stack** — Ghostty (GPU-accelerated) as the base terminal, managed by cmux
- **Idempotent sync** — one script (`sync.sh`) installs Homebrew packages, symlinks every Stow package, provisions mise runtimes, and pulls the default Ollama model — safe to re-run anytime
- **Auto-update prompt** — new shells periodically check the repo for remote commits and offer to pull + sync (Enter to accept); `dotfiles-update --force` checks on demand
- **Polyglot runtimes via mise** — node, bun, pnpm, python, uv, rust, go, pinned centrally instead of per-project

For exact settings of any given tool, read its config directly under the matching Stow package (e.g. `nvim/.config/nvim/init.lua`) — that file is always the source of truth.

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
```
