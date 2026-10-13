# dotfiles

Personal macOS development environment using **GNU Stow** for dotfiles management.

## Stack

- 🍺 **Homebrew** — package management
- 🐚 **zsh + zinit + Starship** — shell, plugins, prompt
- 🔧 **mise** — polyglot runtime manager (node, bun, pnpm, python, uv, rust, go)
- 📦 **pnpm + bun** — JS package managers
- ✏️ **Neovim** — primary code editor
- 👻 **Ghostty** — GPU-accelerated terminal emulator, default terminal
- 🖥️ **herdr** — the agent multiplexer that lives in your terminal
- 🔀 **tmux** — terminal multiplexer
- 🪟 **Tili** — i3-like tiling window manager, written in Rust
- 🐙 **GitHub CLI** — GitHub workflows from the terminal
- 🐙 **lazygit** — terminal UI for git, standalone or inside Neovim (`<leader>gg`); installed via Brewfile, config/theme not managed by this repo
- 🐳 **Colima + Docker CLI** — terminal-only container runtime, Colima runs the backend VM for `docker`
- 🐳 **lazydocker** — terminal UI for docker, same author as lazygit
- 📁 **superfile** — terminal file manager
- 📊 **btop** — resource monitor (CPU, memory, disks, network, processes)

## Quick Start

**Fresh machine** (installs Xcode CLI tools, clones repo, runs sync):
```bash
sh <(curl -fsSL https://raw.githubusercontent.com/itsdezen/dotfiles/main/sync.sh) bootstrap
```

**Existing machine:**
```bash
git clone https://github.com/itsdezen/dotfiles ~/Developer/dotfiles
cd ~/Developer/dotfiles && ./sync.sh
```

`sync.sh` is idempotent — safe to re-run anytime to sync/update. It uses a `#!/bin/sh` shebang, so `./sync.sh` and `sh sync.sh` are equivalent.

**Docker/lazydocker** — run `colima start` once after install to bring up the container runtime VM before using `docker` or `lazydocker`.

## Scripts

| Script | Description |
|--------|-------------|
| `./sync.sh` | Sync everything: Homebrew, dotfiles, runtimes, nvim/tmux plugins — and prune links left behind by dropped packages |
| `./sync.sh bootstrap` | Fresh machine setup: Xcode CLI tools → clone → sync |
| `./sync.sh uninstall` | Remove all dotfiles symlinks, zinit, and TPM |

## Stow Packages

| Package | Symlinks to |
|---------|-------------|
| `zsh` | `~/.zshrc`, `~/.zshenv`, `~/.zprofile` |
| `nvim` | `~/.config/nvim/` |
| `tili` | `~/.config/tili/` |
| `starship` | `~/.config/starship.toml` |
| `ghostty` | `~/.config/ghostty/` |
| `mise` | `~/.config/mise/config.toml` |
| `git` | `~/.gitconfig`, `~/.config/git/ignore` |
| `superfile` | `~/.config/superfile/config.toml`, `~/.config/superfile/hotkeys.toml` |
| `btop` | `~/.config/btop/btop.conf` |
| `tmux` | `~/.tmux.conf` |
| `herdr` | `~/.config/herdr/config.toml` |
| `opencode` | `~/.config/opencode/` (whole directory, folded) |

`opencode` is folded at the directory level on purpose. OpenCode persists `cli.json` with a temp-file + `rename`, which replaces a file-level symlink with a real file and silently detaches it from this repo — the change never shows in Git. Symlinking the directory makes those rewrites land on the tracked file, so TUI settings changes appear as normal Git changes. Runtime artifacts (`node_modules`, `service.json`, …) are ignored by the package's `.gitignore`.

`herdr`, `btop`, and `superfile` are the opposite case — always stowed file-by-file (`--no-folding`), because their target dirs mix tracked config with app-generated state (`herdr` logs/sockets, `btop` `themes/`, `superfile` `theme/`) that must never land in this repo.

## Highlights

- **Unified theme** — Tokyo Night across nvim, Ghostty, superfile, herdr, opencode, and btop for a consistent look everywhere (starship and tmux are terminal-adaptive instead)
- **Keyboard-driven window management** — Tili tiling window manager with built-in floating-window centering
- **OpenCode** — default Build and Plan agents, plus an `/auto` plugin for runtime auto-approval without touching config
- **Idempotent sync** — one script (`sync.sh`) installs Homebrew packages, symlinks every Stow package, and provisions mise runtimes
- **Self-pruning symlinks** — dropping a package from `PACKAGES` doesn't unstow it elsewhere, so `sync.sh` prunes any link back into this repo whose target is gone or belongs to a package no longer listed
- **Cleanup candidates report** — `sync.sh` flags installed Homebrew packages not in the Brewfile (never removes automatically)
- **Auto-update prompt** — new shells periodically check the repo for remote commits and offer to pull + sync (Enter to accept); `dotfiles-update --force` checks on demand
- **Runtimes managed centrally** — mise versions live in this repo instead of per-project

For exact settings of any given tool, read its config directly under the matching Stow package (e.g. `nvim/.config/nvim/init.lua`) — that file is always the source of truth.

## Troubleshooting

**Stow conflict** — `sync.sh` resolves automatically (dotfiles win, no backups).

```bash
./sync.sh        # re-run to fix
```
