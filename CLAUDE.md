# CLAUDE.md

AI assistant instructions for this dotfiles repository. For general documentation, stack overview, scripts, and troubleshooting — see **[README.md](./README.md)**.

---

## Design Philosophy

1. **One script**: `sync.sh` is the single entry point — install, update, repair. No per-tool install scripts.
2. **Modular**: each Stow package is self-contained. Files symlink to `$HOME` via `stow -t "$HOME"`.
3. **Dotfiles win**: conflicts resolved by removing the target file, never creating backups.
4. **Minimal**: no abstractions beyond what the tools need.

---

## Directory Structure

```
dotfiles/
├── sync.sh / stow-install.sh / uninstall.sh
├── Brewfile
├── zsh/        → ~/.zshrc, ~/.zshenv, ~/.zprofile
├── nvim/       → ~/.config/nvim/
├── aerospace/  → ~/.config/aerospace/
├── starship/   → ~/.config/starship.toml
├── zed/        → ~/.config/zed/
├── cmux/       → ~/.config/cmux/
├── ghostty/    → ~/.config/ghostty/
└── mise/       → ~/.config/mise/config.toml
```

---

## Key Config Details

### nvim (`nvim/.config/nvim/lua/`)

- **Colorscheme**: `onedark` warmer + transparent (`plugins/colorscheme.lua`)
- **LazyVim extras**: `coding.blink`, `lang.typescript`, `lang.tailwind`
- **Formatting**: `conform.nvim` — biome (JS/TS/JSX/TSX/JSON/CSS), stylua (Lua)
- **UI**: lualine (powerline separators), bufferline (slant), snacks.indent (chunk scope), noice.nvim (default on), nvim-colorizer
- **Disabled**: tokyonight, catppuccin (`plugins/disabled.lua`)

### zed (`zed/.config/zed/`)

- **Theme**: Catppuccin Espresso Blur (dark) / Iced Latte Blur (light)
- **Font**: MapleMono NF, size 14, ligatures on
- **AI**: Claude Sonnet via anthropic provider, claude-acp MCP server

### ghostty (`ghostty/.config/ghostty/config`)

- **Font**: MapleMono NF, size 12
- **Background**: `#000000`, opacity 0.7, blur on

### zsh (`zsh/.zshrc`)

- Plugin manager: zinit (turbo/lazy)
- Plugins: git (oh-my-zsh), zsh-autosuggestions, fast-syntax-highlighting
- `EDITOR` = `code --wait`
- Sources `~/.zshrc.local` if present (machine-specific overrides, not committed)

---

## AI Assistant Rules

### 1. Always use Stow

- Never create custom symlink scripts or backup files
- Use `stow -t "$HOME" -R <package>` for all symlink operations
- Detect conflicts with `stow -n`, remove conflicting files, then stow

### 2. One script philosophy

- `sync.sh` is the single entry point
- When adding a package: add to `PACKAGES` in both `sync.sh` and `stow-install.sh`

### 3. Conventions

- Stow package dirs: lowercase
- Scripts: `set -euo pipefail`, helpers: `ok/run/warn/abort`
- No banners, no prompts (except destructive ops in `uninstall.sh`)
- Commit style: emoji prefix (`🚀 🐞 🔧 ♻️ 📝 🗑️ ⬆️`)

### 4. When adding features

1. Create/update Stow package directory
2. Add package to `PACKAGES` in `sync.sh` and `stow-install.sh`
3. Add to `Brewfile` if installable via Homebrew
4. **Update docs** (see rule 5)

### 5. Keep docs in sync

Whenever a dotfiles change affects something documented in `README.md` or `CLAUDE.md`, update the relevant doc in the same commit. This includes:

- Stack or tool changes → `README.md` Stack section
- New/removed Stow packages → `README.md` Stow Packages table + Directory Structure above
- Font, theme, or key config changes → `CLAUDE.md` Key Config Details
- New scripts or changed script behavior → `README.md` Scripts table
- New AI rules or conventions → `CLAUDE.md` AI Assistant Rules

**Do not** document ephemeral state (current branch, in-progress work, which PR fixed what).

---

**Maintained by:** @onepercman — https://github.com/onepercman/dotfiles
