#!/usr/bin/env bash
# node-setup.sh — Install Node.js via mise + pnpm + bun

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

# Install Node.js via mise
install_node() {
  if ! command -v mise &>/dev/null; then
    error "mise not found. Please install: brew install mise"
    exit 1
  fi

  # Get default Node version from .node-version or use LTS
  local node_version
  if [[ -f "$SCRIPT_DIR/.node-version" ]]; then
    node_version="$(cat "$SCRIPT_DIR/.node-version" | tr -d '[:space:]')"
  else
    node_version="lts"
  fi

  info "Installing Node.js $node_version via mise..."
  mise install "node@$node_version"
  mise use -g "node@$node_version"

  # Activate mise for current session
  eval "$(mise activate bash)"

  if command -v node &>/dev/null; then
    success "Node.js $(node --version) is ready"
  else
    error "Node.js installation failed. Please check mise configuration."
    exit 1
  fi
}

# Install pnpm
install_pnpm() {
  if command -v pnpm &>/dev/null; then
    success "pnpm already installed ($(pnpm --version))"
    return 0
  fi

  info "Installing pnpm..."
  if command -v npm &>/dev/null; then
    npm install -g pnpm --silent
    success "pnpm $(pnpm --version) installed"
  else
    error "npm not available, cannot install pnpm"
    exit 1
  fi
}

# Install bun
install_bun() {
  if command -v bun &>/dev/null; then
    success "bun already installed ($(bun --version))"
    return 0
  fi

  if ! command -v mise &>/dev/null; then
    error "mise not found. Please install: brew install mise"
    exit 1
  fi

  info "Installing bun via mise..."
  mise install bun

  if command -v bun &>/dev/null; then
    success "bun $(bun --version) installed"
  else
    warn "bun installation may require a new shell session"
  fi
}

# Main
main() {
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "  Node.js Ecosystem Setup"
  echo "═══════════════════════════════════════════════════════════"
  echo ""

  install_node
  echo ""

  # Auto-install pnpm (no prompt)
  install_pnpm
  echo ""

  read -r -p "Install bun? [y/N] " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    install_bun
    echo ""
  fi

  success "Done! Node.js ecosystem setup complete"
  info "Restart your shell or run: source ~/.zshrc"
}

main "$@"
