#!/usr/bin/env bash
# update-all.sh — Update everything (dotfiles, packages, plugins)

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
  echo "║              Update All Script                           ║"
  echo "║                                                           ║"
  echo "╚═══════════════════════════════════════════════════════════╝"
  echo ""
}

# Update git repository
update_git() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " 1. Updating Dotfiles Repository"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  cd "$SCRIPT_DIR"

  # Check if there are uncommitted changes
  if [[ -n $(git status --porcelain) ]]; then
    warn "You have uncommitted changes in the repository"
    read -r -p "Stash changes and update? [Y/n] " response
    if [[ ! "$response" =~ ^[Nn]$ ]]; then
      git stash
      info "Changes stashed"
    else
      warn "Skipping git update"
      return
    fi
  fi

  info "Pulling latest changes from git..."
  git pull

  success "Dotfiles repository updated"
}

# Update Homebrew packages
update_homebrew() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " 2. Updating Homebrew Packages"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if ! command -v brew &>/dev/null; then
    warn "Homebrew not installed, skipping"
    return
  fi

  info "Updating Homebrew..."
  brew update

  info "Upgrading packages..."
  brew upgrade

  info "Cleaning up..."
  brew cleanup

  success "Homebrew packages updated"
}

# Update Stow symlinks
update_stow() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " 3. Updating Stow Symlinks"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if ! command -v stow &>/dev/null; then
    warn "Stow not installed, skipping"
    return
  fi

  cd "$SCRIPT_DIR"
  bash "$SCRIPT_DIR/stow-install.sh" restow

  success "Stow symlinks updated"
}

# Update Node.js
update_node() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " 4. Updating Node.js"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if ! command -v mise &>/dev/null; then
    warn "mise not installed, skipping"
    return
  fi

  # Get current Node version from .node-version
  local node_version
  if [[ -f "$SCRIPT_DIR/.node-version" ]]; then
    node_version="$(cat "$SCRIPT_DIR/.node-version" | tr -d '[:space:]')"
    info "Installing Node.js $node_version..."
    mise install "node@$node_version"
    mise use -g "node@$node_version"
  fi

  # Update npm globals
  if command -v npm &>/dev/null; then
    info "Updating npm global packages..."
    npm update -g
  fi

  # Update pnpm
  if command -v pnpm &>/dev/null; then
    info "Updating pnpm..."
    pnpm add -g pnpm
  fi

  # Update bun
  if command -v mise &>/dev/null; then
    info "Updating bun..."
    mise upgrade bun
  fi

  success "Node.js ecosystem updated"
}

# Update zinit and plugins
update_zinit() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " 5. Updating Zinit & Plugins"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

  if [[ ! -d "$ZINIT_HOME" ]]; then
    warn "zinit not installed, skipping"
    return
  fi

  info "Updating zinit..."
  if [[ -n "$ZSH_VERSION" ]]; then
    # Running in zsh
    zsh -c "source ~/.zshrc && zinit self-update && zinit update --all"
  else
    # Not in zsh, create a temporary script
    zsh -c "
      source ~/.zshrc
      zinit self-update
      zinit update --all
    "
  fi

  success "zinit and plugins updated"
}

# Update Neovim plugins
update_neovim() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " 6. Updating Neovim Plugins"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if ! command -v nvim &>/dev/null; then
    warn "Neovim not installed, skipping"
    return
  fi

  info "Updating Neovim plugins..."
  nvim --headless "+Lazy! sync" +qa

  success "Neovim plugins updated"
}

# Main
main() {
  banner

  echo "This script will update:"
  echo "  1. Dotfiles repository (git pull)"
  echo "  2. Homebrew packages"
  echo "  3. Stow symlinks"
  echo "  4. Node.js ecosystem"
  echo "  5. Zinit & plugins"
  echo "  6. Neovim plugins"
  echo ""

  read -r -p "Continue? [Y/n] " response
  if [[ "$response" =~ ^[Nn]$ ]]; then
    echo "Aborted."
    exit 0
  fi

  update_git
  update_homebrew
  update_stow
  update_node
  update_zinit
  update_neovim

  echo ""
  echo "╔═══════════════════════════════════════════════════════════╗"
  echo "║                                                           ║"
  echo "║                  Update Complete!                         ║"
  echo "║                                                           ║"
  echo "╚═══════════════════════════════════════════════════════════╝"
  echo ""
  success "Everything is up to date!"
  info "Restart your terminal or run: source ~/.zshrc"
}

main "$@"
