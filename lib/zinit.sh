#!/usr/bin/env bash
# lib/zinit.sh — Install and setup zinit (modern, fast plugin manager)

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
    return 1
  fi
}

setup_shell() {
  install_zinit
}
