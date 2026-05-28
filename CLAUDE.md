# CLAUDE.md

**Context and Instructions for AI Assistants**

This file contains comprehensive information about the dotfiles repository structure, design decisions, and usage patterns. Use this as your primary reference when helping users with this repository.

---

## 📋 Repository Overview

### Purpose

This is a **Stow-based dotfiles repository** for macOS, providing a minimal, modular development environment with:

- **GNU Stow** for symlink management (no custom install scripts)
- **Homebrew** for package management
- **Modern shell**: zsh + zinit + Starship prompt
- **Node.js ecosystem**: mise + pnpm + bun
- **Text editor**: Neovim with LSP and modern plugins
- **Window manager**: AeroSpace (i3-like tiling for macOS)
- **Standalone scripts**: All setup scripts can be run independently

### Design Philosophy

1. **Simple**: Use standard tools (Stow) instead of custom installers
2. **Modular**: Each package is self-contained
3. **Flexible**: Run individual scripts as needed
4. **Non-invasive**: Stow handles backups and conflicts
5. **Minimal**: Only essential tools and configurations

---

## 📁 Directory Structure

```
dotfiles/
├── setup.sh              # Quick setup (runs all scripts)
├── brew-install.sh       # Install Homebrew + packages
├── node-setup.sh         # Setup Node.js ecosystem
├── zinit-setup.sh        # Install zinit plugin manager
├── stow-install.sh       # Stow/unstow dotfiles
├── Brewfile              # Homebrew packages
├── .node-version         # Default Node.js version
├── npm-globals.txt       # Global npm packages (optional)
├── .gitignore            # Git ignore rules
│
├── zsh/                  # Zsh package
│   ├── .zshrc            # Main zsh config
│   ├── .zshenv           # Environment variables
│   └── .zprofile         # Login shell config
│
├── nvim/                 # Neovim package
│   └── .config/
│       └── nvim/
│           └── init.lua  # Neovim configuration
│
├── aerospace/            # AeroSpace package
│   └── .config/
│       └── aerospace/
│           └── aerospace.toml
│
├── starship/             # Starship package
│   └── .config/
│       └── starship/
│           └── starship.toml
│
└── zed/                  # Zed editor package
    └── .config/
        └── zed/
            └── settings.json
```

### Stow Package Structure

Each directory (zsh, nvim, etc.) is a **Stow package**. Stow creates symlinks from package files to `$HOME`:

```
dotfiles/zsh/.zshrc → ~/.zshrc
dotfiles/nvim/.config/nvim/init.lua → ~/.config/nvim/init.lua
dotfiles/aerospace/.config/aerospace → ~/.config/aerospace
```

---

## 🚀 Installation & Usage

### Quick Start (Full Setup)

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles
./setup.sh
```

This runs all setup scripts in order:
1. Install Homebrew + packages
2. Install GNU Stow
3. Stow dotfiles
4. Setup zinit
5. Setup Node.js ecosystem

### Individual Scripts

Run scripts independently as needed:

```bash
# Install Homebrew and packages only
./brew-install.sh

# Install Node.js ecosystem only
./node-setup.sh

# Setup zinit only
./zinit-setup.sh

# Stow dotfiles only
./stow-install.sh
```

### Stow Commands

```bash
# Install all packages
./stow-install.sh install

# Reinstall (update symlinks)
./stow-install.sh restow

# Remove all packages
./stow-install.sh remove

# List available packages
./stow-install.sh list

# Manual Stow usage
cd ~/Developer/dotfiles

# Install single package
stow zsh

# Remove single package
stow -D nvim

# Reinstall (useful after updates)
stow -R git

# Dry run (preview changes)
stow -n zsh

# Adopt existing files (merge conflicts)
stow --adopt zsh
```

---

## 📦 Package Details

### zsh Package

**Files:**
- `.zshrc` - Main configuration with zinit, Starship, mise, bun
- `.zshenv` - Environment variables
- `.zprofile` - Login shell config

**Features:**
- **zinit** - Fast plugin manager with turbo mode
- **Starship** - Cross-shell prompt
- **Plugins**: git, zsh-autosuggestions, fast-syntax-highlighting
- **mise integration** - Automatic version management
- **bun integration** - JavaScript runtime

### nvim Package

**Files:**
- `.config/nvim/init.lua` - Complete Neovim configuration

**Features:**
- **lazy.nvim** - Plugin manager
- **Tokyo Night** colorscheme
- **nvim-tree** - File explorer
- **Telescope** - Fuzzy finder
- **Treesitter** - Syntax highlighting
- **LSP**: Lua, TypeScript, HTML, CSS, Tailwind
- **nvim-cmp** - Autocompletion
- **Gitsigns** - Git integration
- **lualine** - Status line

**Key mappings:**
- `<leader>` = Space
- `<leader>ee` - Toggle file explorer
- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `gd` - Go to definition
- `K` - Hover documentation

### aerospace Package

**Files:**
- `.config/aerospace/aerospace.toml` - Window manager config

**Features:**
- i3-like tiling for macOS
- Alt+hjkl navigation
- Alt+1-9 workspace switching
- Alt+Shift+hjkl move windows
- Configurable gaps and layouts

### starship Package

**Files:**
- `.config/starship/starship.toml` - Prompt configuration

**Features:**
- Fast, minimal prompt
- Git status integration
- Command execution time
- Directory truncation

---

## 🛠️ Brewfile Packages

Essential packages installed via Homebrew:

```ruby
brew "mise"        # Polyglot version manager
brew "starship"    # Cross-shell prompt
brew "mole"        # SSH tunneling tool
brew "neovim"      # Text editor

cask "zed"                        # Zed code editor
cask "nikitabobko/tap/aerospace"  # Window manager

cask "font-inconsolata-nerd-font"      # Nerd Font
```

### Adding Packages

Edit `Brewfile` and add:

```ruby
brew "package-name"
# or
cask "cask-name"
```

Then run:
```bash
brew bundle --file=Brewfile
```

### Exporting Current Packages

```bash
brew bundle dump --force
# Then manually edit to keep only essentials
```

---

## 🔧 Customization

### Machine-Specific Configs

Create local configs that won't be tracked:

```bash
# ~/.zshrc.local (sourced by .zshrc)
export WORK_API_KEY="secret"
alias work="cd ~/Work/project"

# ~/.gitconfig.local (included by .gitconfig)
[user]
    name = Work Name
    email = work@email.com
```

### Adding New Packages

1. **Create package directory:**
```bash
mkdir -p newpackage/.config/newapp
```

2. **Add configuration files:**
```bash
# Files in newpackage/ will be symlinked to ~/
touch newpackage/.config/newapp/config.conf
```

3. **Stow the package:**
```bash
stow newpackage
```

4. **Update stow-install.sh** (optional):
```bash
# Add to install section:
stow_package "newpackage"
```

### Updating Dotfiles

```bash
cd ~/Developer/dotfiles

# Edit files
nvim zsh/.zshrc

# Commit changes
git add .
git commit -m "Update zsh config"
git push

# On another machine
git pull
./stow-install.sh restow  # Update symlinks
```

---

## 🐛 Troubleshooting

### Stow Conflicts

**Problem:** "Existing file conflicts with Stow"

**Solutions:**

```bash
# Option 1: Adopt existing files (merge into dotfiles)
stow --adopt zsh
git diff  # Review changes
git restore .  # Discard if unwanted

# Option 2: Remove existing files
rm ~/.zshrc
stow zsh

# Option 3: Backup existing files
mv ~/.zshrc ~/.zshrc.backup
stow zsh
```

### mise Not Loading

```bash
# Check mise installation
which mise
mise --version

# Verify activation in .zshrc
grep 'mise activate' ~/.zshrc

# Manual activation
eval "$(mise activate zsh)"

# Check configuration
mise doctor
```

### zinit Plugins Not Loading

```bash
# Check zinit installation
ls -la ~/.local/share/zinit/zinit.git

# Check plugins
ls -la ~/.local/share/zinit/plugins/

# Reload zinit
source ~/.zshrc

# Show plugin loading times
zinit times

# Reinstall zinit
rm -rf ~/.local/share/zinit
./zinit-setup.sh
```

### Neovim Issues

```bash
# Check Neovim version (needs 0.9+)
nvim --version

# Check plugin installation
nvim +Lazy

# Update plugins
nvim +Lazy sync

# Check LSP
nvim +LspInfo

# Install missing LSP servers
nvim +Mason
```

### AeroSpace Not Starting

```bash
# Check installation
aerospace --version

# Check config syntax
aerospace validate-config

# Restart AeroSpace
aerospace reload-config

# Check logs
log show --predicate 'process == "AeroSpace"' --last 5m
```

---

## 📝 Common Tasks

### Update Everything

```bash
cd ~/Developer/dotfiles

# Update from git
git pull

# Update Homebrew packages
brew update && brew upgrade

# Update Stow symlinks
./stow-install.sh restow

# Update Node.js
mise install node@latest
mise use -g node@latest

# Update npm globals
npm update -g

# Update Neovim plugins
nvim +Lazy sync +qa
```

### Sync to New Machine

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/Developer/dotfiles

# Run full setup
cd ~/Developer/dotfiles
./setup.sh

# Or install selectively
./brew-install.sh
./stow-install.sh
./zinit-setup.sh
./node-setup.sh
```

### Backup Before Changes

```bash
# Backup current configs
tar -czf ~/dotfiles-backup-$(date +%Y%m%d).tar.gz \
  ~/.zshrc ~/.gitconfig ~/.config/nvim ~/.config/aerospace
```

### Uninstall Dotfiles

```bash
cd ~/Developer/dotfiles

# Remove all symlinks
./stow-install.sh remove

# Or remove individual packages
stow -D zsh
stow -D git
stow -D nvim
```

---

## 🤖 AI Assistant Instructions

When helping users with this repository:

### 1. Always Use Stow

- **DO NOT** create custom symlink scripts
- **DO NOT** suggest copying files manually
- **USE** Stow commands for all symlink operations

### 2. Respect Package Structure

- Each package must follow Stow conventions
- Files in `package/` map to `~/`
- Use `.config/` subdirectories for XDG configs

### 3. Keep Scripts Independent

- Each script should be runnable standalone
- Include all necessary functions in the script
- Don't create lib/ directories

### 4. Follow Conventions

**File naming:**
- Stow packages: lowercase directories (zsh, git, nvim)
- Scripts: kebab-case with .sh extension
- Dotfiles: start with . (`.zshrc`, `.gitconfig`)

**Script structure:**
```bash
#!/usr/bin/env bash
set -e  # Exit on error

# Colors and helper functions
# Main functionality
# main() function
# Call main with "$@"
```

### 5. Documentation

- Update README.md for users
- Update this CLAUDE.md for context
- Add comments in configs
- Keep documentation concise

### 6. When Adding Features

1. Create/update Stow package
2. Add to Brewfile if needed
3. Create/update script if needed
4. Update stow-install.sh if needed
5. Update documentation

### 7. Testing Changes

```bash
# Always test in order:
1. Stow dry run: stow -n package
2. Actual stow: stow package
3. Verify symlinks: ls -la ~/
4. Test functionality
5. Unstow: stow -D package
```

---

## 📚 Resources

- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/)
- [Homebrew](https://brew.sh/)
- [zinit](https://github.com/zdharma-continuum/zinit)
- [Starship](https://starship.rs/)
- [mise](https://mise.jdx.dev/)
- [Neovim](https://neovim.io/)
- [lazy.nvim](https://github.com/folke/lazy.nvim)
- [AeroSpace](https://github.com/nikitabobko/AeroSpace)

---

## 📄 License

MIT License - Free to use and modify.

---

**Last Updated:** 2026-05-26
**Maintained By:** @onepercman
**Repository:** https://github.com/onepercman/dotfiles
