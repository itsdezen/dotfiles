#!/usr/bin/env bash
# zinit-setup.sh — Install zinit plugin manager for zsh

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

# Install zinit
install_zinit() {
  local ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

  if [[ -d "$ZINIT_HOME" ]]; then
    success "zinit already installed"
    return 0
  fi

  info "Installing zinit..."

  # Create zinit directory
  mkdir -p "$(dirname "$ZINIT_HOME")"

  # Clone zinit
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"

  if [[ -d "$ZINIT_HOME" ]]; then
    success "zinit installed"
  else
    error "Failed to install zinit"
    exit 1
  fi
}

# Main
main() {
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "  Zinit Plugin Manager Setup"
  echo "═══════════════════════════════════════════════════════════"
  echo ""

  install_zinit

  echo ""
  success "Done! Zinit installed successfully"
  info "Restart your shell or run: source ~/.zshrc"
}

main "$@"
