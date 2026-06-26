# CLAUDE.md

**Context and Instructions for AI Assistants**

This file contains comprehensive information about the dotfiles repository structure, design decisions, and usage patterns. Use this as your primary reference when helping users with this repository.

---

## 📋 Repository Overview

### Purpose

This is a **Stow-based dotfiles repository** for macOS, providing a minimal, modular development environment with:

- **GNU Stow** for symlink management
- **Homebrew** for package management
- **Shell**: zsh + zinit + Starship prompt
- **Runtimes**: mise manages node (lts), bun, python, rust, go
- **JS tooling**: pnpm, bun
- **Editor**: Neovim (LazyVim) + Zed (primary editor = VS Code via `code --wait`)
- **Terminal**: cmux (Ghostty-based)
- **Window manager**: AeroSpace (i3-like tiling for macOS)

### Design Philosophy

1. **One script**: `sync.sh` handles everything — install, update, repair
2. **Modular**: each Stow package is self-contained
3. **Dotfiles win**: conflicts resolved by removing the target, no backups created
4. **Minimal**: only essential tools and configurations

---

## 📁 Directory Structure

```
dotfiles/
├── sync.sh               # Sync everything (install + update, idempotent)
├── stow-install.sh       # Manual stow operations
├── uninstall.sh          # Remove dotfiles
├── Brewfile              # Homebrew packages
├── .node-version         # Default Node.js version for mise (lts)
├── .gitignore
│
├── zsh/
│   ├── .zshrc            # Main config: zinit, plugins, aliases, mise, starship
│   ├── .zshenv           # LANG, LC_ALL, XDG dirs
│   └── .zprofile         # Login shell
│
├── nvim/                 # LazyVim-based Neovim config
│   └── .config/nvim/
│       ├── init.lua
│       ├── lazyvim.json
│       ├── lazy-lock.json
│       └── lua/
│           ├── config/
│           │   ├── autocmds.lua
│           │   ├── keymaps.lua  # Minimal — LazyVim defaults apply
│           │   ├── lazy.lua     # Plugin spec + LazyVim extras
│           │   └── options.lua  # Minimal — LazyVim defaults apply
│           └── plugins/
│               ├── colorscheme.lua    # github_dark (transparent)
│               ├── disabled.lua       # Disable tokyonight, catppuccin
│               ├── formatting.lua     # biome (JS/TS/CSS/JSON), stylua (Lua)
│               ├── smear-cursor.lua   # Animated cursor
│               └── snacks.lua         # Picker config (show hidden files)
│
├── aerospace/
│   └── .config/aerospace/aerospace.toml
│
├── starship/
│   └── .config/starship.toml
│
├── zed/
│   └── .config/zed/
│       ├── settings.json
│       └── keymap.json
│
├── cmux/
│   └── .config/cmux/cmux.json
│
├── ghostty/
│   └── .config/ghostty/config
│
└── mise/
    └── .config/mise/config.toml
```

### Stow Package Structure

Each directory is a **Stow package**. Files symlink to `$HOME`:

```
dotfiles/zsh/.zshrc                   → ~/.zshrc
dotfiles/nvim/.config/nvim/           → ~/.config/nvim/
dotfiles/aerospace/.config/aerospace/ → ~/.config/aerospace/
```

---

## 🚀 Installation & Usage

### Quick Start

```bash
git clone https://github.com/onepercman/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles && ./sync.sh
```

`sync.sh` is idempotent — run it on a fresh machine or to update an existing one.

### What `sync.sh` does

1. **system** — verifies macOS, git, curl
2. **homebrew** — installs if missing; runs `brew trust nikitabobko/tap` (Homebrew 6.x requirement); runs `brew bundle`
3. **dotfiles** — restows all 8 packages; conflicting real files removed via `stow -n` dry-run detection
4. **shell** — installs zinit if missing
5. **runtimes** — installs node/bun/pnpm via mise if missing
6. **editor** — runs `nvim --headless "+Lazy! sync"`

### Stow Commands

```bash
# Manual stow operations
./stow-install.sh [install|restow|remove|list]

# Single package
stow -t "$HOME" -R zsh      # restow
stow -t "$HOME" -D nvim     # remove
stow -n -t "$HOME" zsh      # dry run
```

---

## 📦 Package Details

### zsh Package

**Files:** `.zshrc`, `.zshenv`, `.zprofile`

**`.zshenv`** — loaded in every shell context:
- `LANG`, `LC_ALL` = `en_US.UTF-8`
- XDG dirs: `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME`

**`.zshrc`** features:
- **zinit** (plugin manager) with turbo/lazy loading
- **Plugins**: git (oh-my-zsh), zsh-autosuggestions, fast-syntax-highlighting
- **Aliases**: `ll`, `la`, `..`, `...`, `g`, `v` (nvim), `dev`, `dots`, `zrc`, `reload`
- **mise** — `eval "$(mise activate zsh)"` for runtime management
- **Starship** — `eval "$(starship init zsh)"`
- **EDITOR** = `code --wait` (VS Code)
- **Local overrides** — sources `~/.zshrc.local` if present

### nvim Package

**LazyVim-based** setup. `lazy.lua` loads:
- `LazyVim/LazyVim` base
- `lazyvim.plugins.extras.coding.blink` — blink.cmp completion
- `lazyvim.plugins.extras.lang.typescript` — TypeScript LSP/tools
- `lazyvim.plugins.extras.lang.tailwind` — Tailwind CSS support
- Custom `plugins/` directory

**Custom plugins:**
- **colorscheme**: `github_dark` (transparent) via `projekt0n/github-nvim-theme`; tokyonight and catppuccin disabled
- **formatting**: `conform.nvim` — biome for JS/TS/JSX/TSX/JSON/CSS, stylua for Lua
- **snacks.nvim**: picker shows hidden + ignored files
- **smear-cursor**: animated cursor movement

**Keymaps**: LazyVim defaults — no custom keymaps defined.

### aerospace Package

**Workspaces** (5 total):
- `alt-w` / `alt-shift-w` → `work` — Zed, Terminal, cmux (auto-assigned)
- `alt-e` / `alt-shift-e` → `entertain` — Chrome/media
- `alt-1/2/3` → numbered backups

**Navigation:**
- `alt-hjkl` — focus window
- `alt-shift-hjkl` — move window
- `alt-/` — toggle tiles layout
- `alt-,` — toggle accordion layout
- `alt-shift-;` → service mode (reset, flatten, float/tile toggle)

**Auto-assign rules:**
- Zed, Terminal, cmux → `work` workspace (tiled)
- System Preferences, Activity Monitor, Calculator, Passwords → floating

**Gaps:** 16px inner + outer on all sides.

### starship Package

Powerline-style prompt (no newline):
- Segments: OS icon → directory (truncated to 3, icons for common dirs) → git branch + status → docker context
- Colors: neutral grays (`#FAFAFA`, `#D4D4D4`, `#A3A3A3`, `#525252`)
- Git indicators: staged `+`, modified `!`, untracked `?`, deleted `✘`, ahead `⇡`, behind `⇣`

### zed Package

**Files:** `settings.json`, `keymap.json`

**Key settings:**
- **Theme**: Catppuccin Macchiato Blur (dark) / Iced Latte Blur (light)
- **Font**: JetBrains Mono Nerd Font, size 14, ligatures enabled
- **AI**: Claude Sonnet (anthropic), claude-acp MCP server
- **Vim mode**: disabled
- **Format on save**: enabled (language server)
- **Auto-save**: 1000ms delay
- **Project panel**: right side, 240px, git status shown
- **Extensions**: catppuccin-blur, colored-zed-icons-theme, html, lua, toml (auto-install)
- **Telemetry**: disabled

### mise Package

**File:** `.config/mise/config.toml`

Manages all runtimes globally:
```toml
[tools]
node = "lts"
bun = "latest"
python = "latest"
rust = "latest"
go = "latest"
```

### cmux Package

Ghostty-based terminal with vertical tabs and AI agent notifications. Config at `.config/cmux/cmux.json`.

### ghostty Package

Ghostty terminal emulator config at `.config/ghostty/config`.

---

## 🛠️ Brewfile Packages

```ruby
brew "mise"       # polyglot version manager (node, bun, python, rust, go)
brew "starship"   # cross-shell prompt
brew "mole"       # SSH tunneling tool
brew "neovim"     # text editor
brew "fd"         # fast find (used by snacks.nvim picker)

cask "zed"
cask "cmux"                              # Ghostty-based terminal
cask "nikitabobko/tap/aerospace"         # window manager (third-party tap)
cask "font-jetbrains-mono-nerd-font"
```

> **Note (Homebrew 6.x):** `nikitabobko/tap` requires `brew trust nikitabobko/tap` before install. `sync.sh` handles this automatically.

### Adding Packages

```bash
# Edit Brewfile, then:
./sync.sh
# or just:
brew bundle --file=Brewfile
```

---

## 🔧 Customization

### Machine-Specific Configs

```bash
# ~/.zshrc.local — sourced by .zshrc if it exists (not committed)
export WORK_API_KEY="secret"
alias work="cd ~/Work/project"
```

### Adding New Stow Packages

1. Create package following Stow conventions:
```bash
mkdir -p newpackage/.config/newapp
touch newpackage/.config/newapp/config.toml
```

2. Add to `PACKAGES` in both `sync.sh` and `stow-install.sh`:
```bash
PACKAGES=(zsh nvim aerospace starship zed cmux ghostty mise newpackage)
```

3. Run `./sync.sh`.

### Updating Dotfiles

```bash
nvim zsh/.zshrc
git add . && git commit -m "🔧 ..." && git push

# On another machine
git pull && ./sync.sh
```

---

## 🐛 Troubleshooting

### Stow Conflicts

`sync.sh` handles automatically — uses `stow -n` dry-run to detect conflicting real files, removes them, then stows. Dotfiles always win; no backups created.

```bash
# Manual: remove conflict and restow
rm ~/.zshrc && stow -t "$HOME" zsh
# Or just re-run:
./sync.sh
```

### mise Not Loading

```bash
which mise && mise --version
eval "$(mise activate zsh)"   # manual activation
mise doctor
mise ls                        # check installed runtimes
```

### zinit Plugins Not Loading

```bash
ls ~/.local/share/zinit/zinit.git   # verify install
source ~/.zshrc                     # reload
zinit times                         # show load times
# Reinstall: rm -rf ~/.local/share/zinit && ./sync.sh
```

### Neovim Issues

```bash
nvim --version          # needs 0.10+
nvim +Lazy              # plugin status
nvim +LspInfo           # LSP status
nvim +Mason             # install LSP servers
# Resync plugins: nvim --headless "+Lazy! sync" +qa
```

### AeroSpace Not Starting

```bash
aerospace --version
aerospace validate-config
aerospace reload-config
log show --predicate 'process == "AeroSpace"' --last 5m
```

---

## 📝 Common Tasks

### Sync / Update Everything

```bash
cd ~/Developer/dotfiles && git pull && ./sync.sh
```

### Sync to New Machine

```bash
git clone https://github.com/onepercman/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles && ./sync.sh
```

### Uninstall

```bash
cd ~/Developer/dotfiles && ./uninstall.sh
```

---

## 🤖 AI Assistant Instructions

### 1. Always Use Stow

- **DO NOT** create custom symlink scripts or backup files
- **USE** `stow -t "$HOME" -R package` for all symlink operations
- Conflict resolution: detect with `stow -n`, remove conflicting files, then stow

### 2. One Script Philosophy

- `sync.sh` is the single entry point for install + update
- When adding a package: add to `PACKAGES` array in both `sync.sh` and `stow-install.sh`
- No standalone install scripts per-tool

### 3. Follow Conventions

- Stow packages: lowercase directory names
- Scripts: `set -euo pipefail`, minimal output helpers (ok/run/warn/abort)
- No banners, no prompts (except destructive operations in `uninstall.sh`)
- Commit style: emoji prefix (🚀 🐞 🔧 ♻️ 📝 🗑️ ⬆️)

### 4. When Adding Features

1. Create/update Stow package directory
2. Add package to `PACKAGES` in `sync.sh` and `stow-install.sh`
3. Add to `Brewfile` if installable via Homebrew
4. Update this `CLAUDE.md`

---

## 📚 Resources

- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/)
- [Homebrew](https://brew.sh/)
- [zinit](https://github.com/zdharma-continuum/zinit)
- [Starship](https://starship.rs/)
- [mise](https://mise.jdx.dev/)
- [LazyVim](https://lazyvim.org/)
- [AeroSpace](https://github.com/nikitabobko/AeroSpace)
- [Zed](https://zed.dev/docs)

---

**Last Updated:** 2026-06-25
**Maintained By:** @onepercman
**Repository:** https://github.com/onepercman/dotfiles
