#!/usr/bin/env bash
# setup.sh — Quick setup script for complete environment

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
  echo "║           Dotfiles Quick Setup Script                    ║"
  echo "║                                                           ║"
  echo "╚═══════════════════════════════════════════════════════════╝"
  echo ""
}

# Check macOS
check_macos() {
  if [[ "$(uname)" != "Darwin" ]]; then
    error "This script is for macOS only"
    exit 1
  fi
  success "macOS detected"
}

# Main
main() {
  banner
  check_macos

  echo ""
  echo "This script will install:"
  echo "  1. Homebrew + packages (mise, mole, starship, neovim, aerospace)"
  echo "  2. GNU Stow"
  echo "  3. Dotfiles (zsh, git, nvim, aerospace, starship)"
  echo "  4. Git user configuration"
  echo "  5. Zinit plugin manager"
  echo "  6. Node.js ecosystem (via mise, pnpm, bun)"
  echo ""

  read -r -p "Continue? [Y/n] " response
  if [[ "$response" =~ ^[Nn]$ ]]; then
    echo "Aborted."
    exit 0
  fi

  # Step 1: Install Homebrew and packages
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Step 1: Homebrew & Packages"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  bash "$SCRIPT_DIR/brew-install.sh"

  # Step 2: Install GNU Stow if not installed
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Step 2: GNU Stow"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if ! command -v stow &>/dev/null; then
    info "Installing GNU Stow..."
    brew install stow
    success "GNU Stow installed"
  else
    success "GNU Stow already installed"
  fi

  # Step 3: Stow dotfiles
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Step 3: Dotfiles"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  bash "$SCRIPT_DIR/stow-install.sh" install

  # Step 4: Configure Git
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Step 4: Git Configuration"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  bash "$SCRIPT_DIR/git-config.sh"

  # Step 5: Setup zinit
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Step 5: Zinit Plugin Manager"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  bash "$SCRIPT_DIR/zinit-setup.sh"

  # Step 6: Setup Node.js
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Step 6: Node.js Ecosystem"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  bash "$SCRIPT_DIR/node-setup.sh"

  # Done
  echo ""
  echo "╔═══════════════════════════════════════════════════════════╗"
  echo "║                                                           ║"
  echo "║                    Setup Complete!                        ║"
  echo "║                                                           ║"
  echo "╚═══════════════════════════════════════════════════════════╝"
  echo ""
  success "All done!"
  echo ""
  info "Next steps:"
  echo "  1. Restart your terminal or run: source ~/.zshrc"
  echo "  2. Start using AeroSpace window manager"
  echo "  3. Customize configs in ~/.zshrc.local (machine-specific)"
  echo ""
  info "Useful commands:"
  echo "  ./update-all.sh    - Update everything"
  echo "  ./uninstall.sh     - Uninstall dotfiles"
  echo ""
}

main "$@"
