#!/usr/bin/env bash
# uninstall.sh — Remove dotfiles and optionally uninstall packages

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Print banner
banner() {
  echo ""
  echo "╔═══════════════════════════════════════════════════════════╗"
  echo "║                                                           ║"
  echo "║              Dotfiles Uninstall Script                   ║"
  echo "║                                                           ║"
  echo "╚═══════════════════════════════════════════════════════════╝"
  echo ""
}

# Remove Stow packages
remove_stow() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Removing Dotfiles Symlinks"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if ! command -v stow &>/dev/null; then
    error "Stow not installed, cannot remove symlinks"
    return 1
  fi

  cd "$SCRIPT_DIR"
  bash "$SCRIPT_DIR/stow-install.sh" remove

  success "Dotfiles symlinks removed"
}

# Remove zinit
remove_zinit() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Removing Zinit"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit"

  if [[ -d "$ZINIT_HOME" ]]; then
    read -r -p "Remove zinit directory? [y/N] " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      info "Removing zinit..."
      rm -rf "$ZINIT_HOME"
      success "zinit removed"
    else
      info "Keeping zinit"
    fi
  else
    info "zinit not found"
  fi
}

# Remove Node.js
remove_node() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Removing Node.js"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Remove bun
  if command -v bun &>/dev/null; then
    read -r -p "Remove bun? [y/N] " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      info "Removing bun..."
      rm -rf "$HOME/.bun"
      success "bun removed"
    fi
  fi

  # Note about mise and pnpm
  warn "Note: mise and pnpm are managed by Homebrew"
  info "To remove them, run: brew uninstall mise"
  info "pnpm can be removed with: npm uninstall -g pnpm"
}

# Remove Homebrew packages
remove_homebrew() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Removing Homebrew Packages"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if ! command -v brew &>/dev/null; then
    info "Homebrew not installed"
    return
  fi

  warn "This will remove packages from Brewfile:"
  echo "  - mise, mole, starship, neovim"
  echo "  - AeroSpace"
  echo "  - Fonts"
  echo ""

  read -r -p "Remove Homebrew packages? [y/N] " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    info "Removing Homebrew packages..."

    # Remove packages
    brew uninstall mise mole starship neovim 2>/dev/null || true
    brew uninstall --cask nikitabobko/tap/aerospace 2>/dev/null || true
    brew uninstall --cask font-fantasque-sans-mono-nerd-font 2>/dev/null || true

    success "Homebrew packages removed"
  else
    info "Keeping Homebrew packages"
  fi
}

# Remove Neovim data
remove_neovim_data() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Removing Neovim Data"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local nvim_dirs=(
    "$HOME/.local/share/nvim"
    "$HOME/.local/state/nvim"
    "$HOME/.cache/nvim"
  )

  for dir in "${nvim_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
      read -r -p "Remove $(basename $(dirname $dir))/$(basename $dir)? [y/N] " response
      if [[ "$response" =~ ^[Yy]$ ]]; then
        info "Removing $dir..."
        rm -rf "$dir"
        success "$(basename $dir) removed"
      fi
    fi
  done
}

# Backup current configs
backup_configs() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Backup Current Configs"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  read -r -p "Create backup before uninstall? [Y/n] " response
  if [[ ! "$response" =~ ^[Nn]$ ]]; then
    local backup_file="$HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    info "Creating backup: $backup_file"

    tar -czf "$backup_file" \
      -C "$HOME" \
      .zshrc .zshenv .zprofile \
      .gitconfig .gitignore_global \
      .config/nvim \
      .config/aerospace \
      .config/starship \
      2>/dev/null || true

    success "Backup created: $backup_file"
  fi
}

# Main
main() {
  banner

  warn "⚠️  WARNING: This will remove your dotfiles configuration!"
  echo ""
  echo "This script will:"
  echo "  1. Create a backup (optional)"
  echo "  2. Remove Stow symlinks"
  echo "  3. Remove zinit (optional)"
  echo "  4. Remove Node.js tools (optional)"
  echo "  5. Remove Homebrew packages (optional)"
  echo "  6. Remove Neovim data (optional)"
  echo ""

  read -r -p "Are you sure you want to continue? [y/N] " response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi

  backup_configs
  remove_stow

  echo ""
  read -r -p "Continue with optional removals? [y/N] " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    remove_zinit
    remove_node
    remove_neovim_data
    remove_homebrew
  fi

  echo ""
  echo "╔═══════════════════════════════════════════════════════════╗"
  echo "║                                                           ║"
  echo "║                Uninstall Complete!                        ║"
  echo "║                                                           ║"
  echo "╚═══════════════════════════════════════════════════════════╝"
  echo ""
  success "Dotfiles uninstalled"
  echo ""
  info "Note: To completely remove Homebrew, run:"
  info "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)\""
  echo ""
  info "The dotfiles repository is still in: $SCRIPT_DIR"
  info "You can remove it with: rm -rf $SCRIPT_DIR"
}

main "$@"
