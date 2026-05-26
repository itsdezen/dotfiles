# dotfiles

Personal macOS development environment using **GNU Stow** for dotfiles management.

## Features

- 🔗 **GNU Stow** - Simple symlink management
- 🍺 **Homebrew** - Package management
- 🐚 **zsh + zinit + Starship** - Modern shell with fast plugin manager
- 📦 **mise + pnpm + bun** - Node.js ecosystem
- ✏️  **Neovim** - LSP-powered text editor
- 🪟 **AeroSpace** - i3-like tiling window manager for macOS

## Quick Start

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles

# Run full setup (installs everything)
./setup.sh
```

## Manual Installation

Install components individually:

```bash
# Install Homebrew and packages
./brew-install.sh

# Install GNU Stow (if not already installed)
brew install stow

# Install dotfiles with Stow
./stow-install.sh

# Setup shell (zinit plugin manager)
./zinit-setup.sh

# Setup Node.js ecosystem
./node-setup.sh
```

## Available Scripts

| Script | Description |
|--------|-------------|
| `./setup.sh` | Full automatic setup (runs all scripts) |
| `./brew-install.sh` | Install Homebrew + packages |
| `./stow-install.sh` | Manage dotfiles with Stow |
| `./zinit-setup.sh` | Install zinit plugin manager |
| `./node-setup.sh` | Setup Node.js ecosystem |
| `./update-all.sh` | Update everything (brew, stow, node, plugins) |
| `./uninstall.sh` | Uninstall dotfiles and packages |

## Stow Usage

```bash
# Install all packages
./stow-install.sh install

# Update symlinks
./stow-install.sh restow

# Remove all packages
./stow-install.sh remove

# Manual usage
stow zsh          # Install zsh package
stow -D nvim      # Remove nvim package
stow -R nvim      # Reinstall nvim package
```

## Directory Structure

```
dotfiles/
├── zsh/                 # Zsh configuration
├── nvim/                # Neovim configuration
├── aerospace/           # AeroSpace window manager
├── starship/            # Starship prompt
├── setup.sh             # Full setup script
├── brew-install.sh      # Install Homebrew
├── stow-install.sh      # Stow manager
├── zinit-setup.sh       # Install zinit
├── node-setup.sh        # Install Node.js
├── update-all.sh        # Update everything
└── uninstall.sh         # Uninstall script
```

## Configuration

### Machine-Specific Settings

Create local configs that won't be tracked:

```bash
# ~/.zshrc.local
export WORK_API_KEY="secret"
alias work="cd ~/Work"

# Git config (manual setup)
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

## Neovim Key Mappings

- `<leader>` = Space
- `<leader>ee` - Toggle file explorer
- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `gd` - Go to definition
- `K` - Hover documentation

## AeroSpace Key Mappings

- `Alt+hjkl` - Navigate windows
- `Alt+Shift+hjkl` - Move windows
- `Alt+1-9` - Switch workspaces
- `Alt+Shift+1-9` - Move to workspace

## Updating

Use the automated update script:

```bash
./update-all.sh
```

This will update:
- Dotfiles repository (git pull)
- Homebrew packages
- Stow symlinks
- Node.js ecosystem
- Zinit & plugins
- Neovim plugins

Or update manually:

```bash
cd ~/Developer/dotfiles
git pull
brew update && brew upgrade
./stow-install.sh restow
nvim +Lazy sync +qa
```

## Troubleshooting

### Stow Conflicts

If Stow reports conflicts with existing files:

```bash
# Backup existing files
mv ~/.zshrc ~/.zshrc.backup

# Or adopt existing files into dotfiles
stow --adopt zsh

# Review changes
git diff
```

### Neovim Plugin Issues

```bash
# Check plugin status
nvim +Lazy

# Update all plugins
nvim +Lazy sync

# Check LSP status
nvim +LspInfo

# Install LSP servers
nvim +Mason
```

## Uninstall

Use the automated uninstall script:

```bash
./uninstall.sh
```

This will:
- Create backup (optional)
- Remove Stow symlinks
- Remove zinit (optional)
- Remove Node.js tools (optional)
- Remove Homebrew packages (optional)
- Remove Neovim data (optional)

Or remove manually:

```bash
cd ~/Developer/dotfiles
./stow-install.sh remove
```

## Documentation

- See [CLAUDE.md](CLAUDE.md) for detailed documentation and AI assistant context
- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/)
- [Neovim Config](https://neovim.io/doc/)
- [AeroSpace](https://github.com/nikitabobko/AeroSpace)

## License

MIT
