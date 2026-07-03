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
- 🔨 **Hammerspoon** — macOS automation via Lua
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
| `hammerspoon` | `~/.hammerspoon/` |
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

## Highlights

- **Unified theme** — Kanagawa Dragon across nvim, Ghostty, Zed, and btop for a consistent look everywhere
- **AI-native editing** — Zed ships with Claude built-in; Ollama runs local models as an offline fallback
- **Keyboard-driven window management** — AeroSpace tiling + Hammerspoon Lua automation
- **Terminal stack** — Ghostty (GPU-accelerated) as the base terminal, managed by cmux, with tmux available for classic session management
- **Idempotent sync** — one script (`sync.sh`) installs Homebrew packages, symlinks every Stow package, provisions mise runtimes, and pulls the default Ollama model — safe to re-run anytime
- **Polyglot runtimes via mise** — node, bun, python, rust, go, pinned centrally instead of per-project

For exact settings of any given tool, read its config directly under the matching Stow package (e.g. `zed/.config/zed/settings.json`) — that file is always the source of truth.

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
