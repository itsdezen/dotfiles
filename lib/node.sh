#!/usr/bin/env bash
# lib/node.sh — Install Node.js via nvm + pnpm + bun

install_node() {
  # nvm should already be installed via Brewfile
  export NVM_DIR="$HOME/.nvm"

  # Check if nvm is installed
  if [[ ! -d "$NVM_DIR" ]]; then
    warn "nvm not found — installing manually..."
    if command -v brew &>/dev/null && brew list nvm &>/dev/null; then
      # nvm installed via brew, set it up
      if [[ -f "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
        source "/opt/homebrew/opt/nvm/nvm.sh"
      elif [[ -f "/usr/local/opt/nvm/nvm.sh" ]]; then
        source "/usr/local/opt/nvm/nvm.sh"
      fi
    else
      error "Cannot find nvm. Please install: brew install nvm"
      return 1
    fi
  fi

  # Load nvm into current shell
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
  elif [[ -f "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
    source "/opt/homebrew/opt/nvm/nvm.sh"
  elif [[ -f "/usr/local/opt/nvm/nvm.sh" ]]; then
    source "/usr/local/opt/nvm/nvm.sh"
  else
    error "Cannot load nvm. Please check installation."
    return 1
  fi

  # Get default Node version from .node-version or use LTS
  local node_version="--lts"
  if [[ -f "$DOTFILES_DIR/.node-version" ]]; then
    node_version="$(cat "$DOTFILES_DIR/.node-version")"
  fi

  info "Installing Node.js $node_version via nvm..."
  nvm install "$node_version"
  nvm use "$node_version"
  nvm alias default "$node_version"

  success "Node.js $(node --version) is ready"

  # Install global npm packages
  if [[ -f "$DOTFILES_DIR/npm-globals.txt" ]]; then
    info "Installing global npm packages..."
    while IFS= read -r package || [[ -n "$package" ]]; do
      [[ "$package" =~ ^#.*$ || -z "$package" ]] && continue
      npm install -g "$package" --silent
      info "  + $package"
    done < "$DOTFILES_DIR/npm-globals.txt"
    success "npm globals installed"
  fi
}

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
    warn "npm not available, skipping pnpm installation"
    return 1
  fi
}

install_bun() {
  if command -v bun &>/dev/null; then
    success "bun already installed ($(bun --version))"
    return 0
  fi

  info "Installing bun..."
  curl -fsSL https://bun.sh/install | bash

  # Add bun to PATH for current session
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"

  if command -v bun &>/dev/null; then
    success "bun $(bun --version) installed"
  else
    warn "bun installation may require a new shell session"
  fi
}
