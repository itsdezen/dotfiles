#!/usr/bin/env bash
# lib/brew.sh — Install Homebrew and run Brewfile

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

install_packages() {
  local brewfile="$1"
  if [[ ! -f "$brewfile" ]]; then
    warn "Brewfile not found at: $brewfile"
    return
  fi

  info "Installing packages from Brewfile..."
  brew bundle --file="$brewfile"
  success "Packages installed"
}
