#!/usr/bin/env bash
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; NC='\033[0m'
ok()   { printf "  ${G}✓${NC} %s\n" "$*"; }
warn() { printf "  ${Y}!${NC} %s\n" "$*"; }
abort(){ printf "  ${R}✗${NC} %s\n" "$*" >&2; exit 1; }

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(zsh nvim aerospace starship zed cmux ghostty mise)

command -v stow &>/dev/null || abort "stow not found — run: brew install stow"
cd "$DOTFILES"

stow_pkg() {
  local pkg="$1" action="$2"
  [[ -d "$DOTFILES/$pkg" ]] || { warn "not found: $pkg"; return; }
  if stow -t "$HOME" "$action" "$pkg" 2>/dev/null; then
    ok "$pkg"
  else
    warn "$pkg failed"
  fi
}

case "${1:-install}" in
  install|restow) for p in "${PACKAGES[@]}"; do stow_pkg "$p" "-R"; done ;;
  remove)         for p in "${PACKAGES[@]}"; do stow_pkg "$p" "-D"; done ;;
  list)           printf '%s\n' "${PACKAGES[@]}" ;;
  *)              printf "usage: %s [install|restow|remove|list]\n" "$0"; exit 1 ;;
esac
