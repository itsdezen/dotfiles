#!/usr/bin/env bash
# brew-install.sh — Install Homebrew and packages from Brewfile

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

# Install Homebrew
install_homebrew() {
  if command -v brew &>/dev/null; then
    success "Homebrew already installed ($(brew --version | head -1))"
    info "Updating Homebrew..."
    brew update --quiet
  else
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH (Apple Silicon)
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    success "Homebrew installed"
  fi
}

# Install packages from Brewfile
install_packages() {
  local brewfile="${1:-Brewfile}"

  if [[ ! -f "$brewfile" ]]; then
    error "Brewfile not found at: $brewfile"
    exit 1
  fi

  info "Installing packages from Brewfile..."
  brew bundle --file="$brewfile"
  success "Packages installed"
}

# Main
main() {
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "  Homebrew Installation Script"
  echo "═══════════════════════════════════════════════════════════"
  echo ""

  install_homebrew
  install_packages "$1"

  echo ""
  success "Done! Packages installed successfully"
}

main "$@"
