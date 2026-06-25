#!/usr/bin/env bash
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; NC='\033[0m'
ok()   { printf "  ${G}✓${NC} %s\n" "$*"; }
warn() { printf "  ${Y}!${NC} %s\n" "$*"; }
abort(){ printf "  ${R}✗${NC} %s\n" "$*" >&2; exit 1; }

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf "${Y}!${NC} Remove all dotfiles symlinks? [y/N] "
read -r resp
[[ "$resp" =~ ^[Yy]$ ]] || { echo "aborted"; exit 0; }

bash "$DOTFILES/stow-install.sh" remove

ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit"
if [[ -d "$ZINIT_HOME" ]]; then
  rm -rf "$ZINIT_HOME"
  ok "zinit removed"
fi

printf "\n${G}✓${NC} done\n"
warn "Homebrew packages and mise runtimes were not removed"
warn "To remove Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)\""
