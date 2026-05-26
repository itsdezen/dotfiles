#!/usr/bin/env bash
# git-config.sh — Configure git user information

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

# Configure git user
configure_git() {
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "  Git User Configuration"
  echo "═══════════════════════════════════════════════════════════"
  echo ""

  # Check current git config
  local current_name=$(git config --global user.name 2>/dev/null || echo "")
  local current_email=$(git config --global user.email 2>/dev/null || echo "")

  if [[ -n "$current_name" && -n "$current_email" ]]; then
    echo "Current git configuration:"
    echo "  Name:  $current_name"
    echo "  Email: $current_email"
    echo ""
    read -r -p "Do you want to change it? [y/N] " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      success "Keeping current git configuration"
      return 0
    fi
  fi

  # Get user input
  echo ""
  read -r -p "Enter your name: " git_name
  read -r -p "Enter your email: " git_email

  # Validate input
  if [[ -z "$git_name" || -z "$git_email" ]]; then
    error "Name and email cannot be empty"
    exit 1
  fi

  # Configure git
  info "Configuring git..."
  git config --global user.name "$git_name"
  git config --global user.email "$git_email"

  echo ""
  success "Git configured successfully!"
  echo ""
  echo "Configuration:"
  echo "  Name:  $(git config --global user.name)"
  echo "  Email: $(git config --global user.email)"
}

# Main
main() {
  configure_git
}

main "$@"
