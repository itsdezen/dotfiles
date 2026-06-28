#!/usr/bin/env bash
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; D='\033[2m'; B='\033[1m'; NC='\033[0m'
ok()      { printf "  ${G}✓${NC} %s\n" "$*"; }
run()     { printf "  ${D}→${NC} %s\n" "$*"; }
warn()    { printf "  ${Y}!${NC} %s\n" "$*"; }
abort()   { printf "  ${R}✗${NC} %s\n" "$*" >&2; exit 1; }
section() { printf "\n${B}%s${NC}\n" "$*"; }

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(zsh nvim aerospace starship zed ghostty tmux mise)

# ── stow helpers ────────────────────────────────────────────────────────────────

stow_pkg() {
  local pkg="$1"
  [[ -d "$DOTFILES/$pkg" ]] || { warn "package not found: $pkg"; return; }
  stow -n -t "$HOME" -R "$pkg" 2>&1 \
    | grep '^\s*\*' | sed 's/.*: //' \
    | while IFS= read -r conflict; do rm -rf "$HOME/$conflict"; done \
    || true
  if stow -t "$HOME" -R "$pkg" 2>/dev/null; then
    ok "$pkg"
  else
    warn "$pkg stow failed"
  fi
}

unstow_pkg() {
  local pkg="$1"
  [[ -d "$DOTFILES/$pkg" ]] || return
  if stow -t "$HOME" -D "$pkg" 2>/dev/null; then
    ok "$pkg"
  else
    warn "$pkg unstow failed"
  fi
}

# ── uninstall ───────────────────────────────────────────────────────────────────

cmd_uninstall() {
  printf "${Y}!${NC} Remove all dotfiles symlinks? [y/N] "
  read -r resp
  [[ "$resp" =~ ^[Yy]$ ]] || { echo "aborted"; exit 0; }

  section "dotfiles"
  command -v stow &>/dev/null || abort "stow not found"
  cd "$DOTFILES"
  for pkg in "${PACKAGES[@]}"; do unstow_pkg "$pkg"; done

  section "shell"
  ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit"
  if [[ -d "$ZINIT_HOME" ]]; then
    rm -rf "$ZINIT_HOME"
    ok "zinit removed"
  fi

  printf "\n${G}✓${NC} done\n"
  warn "Homebrew packages and mise runtimes were not removed"
  warn "To remove Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)\""
}

# ── sync ────────────────────────────────────────────────────────────────────────

cmd_sync() {
  # ── system ────────────────────────────────────────────────────────────────────
  section "system"
  [[ "$(uname)" == "Darwin" ]] || abort "macOS only"
  ok "macOS $(sw_vers -productVersion)"
  command -v git  &>/dev/null || abort "git missing — run: xcode-select --install"
  command -v curl &>/dev/null || abort "curl missing — run: xcode-select --install"
  ok "git · curl"

  # ── homebrew ──────────────────────────────────────────────────────────────────
  section "homebrew"
  if ! command -v brew &>/dev/null; then
    run "installing"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >/dev/null
    [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [[ -f /usr/local/bin/brew    ]] && eval "$(/usr/local/bin/brew shellenv)"
    command -v brew &>/dev/null || abort "Homebrew install failed"
  fi
  ok "Homebrew $(brew --version | head -1 | awk '{print $2}')"
  brew trust nikitabobko/tap 2>/dev/null || true
  run "bundle"
  brew bundle --file="$DOTFILES/Brewfile" --quiet || abort "brew bundle failed"
  ok "packages"

  # ── dotfiles ──────────────────────────────────────────────────────────────────
  section "dotfiles"
  command -v stow &>/dev/null || abort "stow not found — run: brew install stow"
  cd "$DOTFILES"
  for pkg in "${PACKAGES[@]}"; do stow_pkg "$pkg"; done

  # ── shell ─────────────────────────────────────────────────────────────────────
  section "shell"
  ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
  if [[ ! -d "$ZINIT_HOME" ]]; then
    run "installing zinit"
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone --quiet https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
  fi
  ok "zinit"

  # ── runtimes ──────────────────────────────────────────────────────────────────
  section "runtimes"
  command -v mise &>/dev/null || abort "mise not found"
  eval "$(mise activate bash)"

  NODE_VER="$(tr -d '[:space:]' < "$DOTFILES/.node-version" 2>/dev/null || echo "lts")"
  if ! command -v node &>/dev/null; then
    run "installing node $NODE_VER"
    mise install "node@$NODE_VER" >/dev/null
    mise use -g "node@$NODE_VER" >/dev/null
    eval "$(mise activate bash)"
  fi
  ok "node $(node --version)"

  if ! command -v bun &>/dev/null; then
    run "installing bun"
    mise install bun >/dev/null
    mise use -g bun >/dev/null
    eval "$(mise activate bash)"
  fi
  ok "bun $(bun --version)"

  if ! command -v pnpm &>/dev/null; then
    run "installing pnpm"
    npm install -g pnpm --silent
  fi
  ok "pnpm $(pnpm --version)"

  # ── editor ────────────────────────────────────────────────────────────────────
  section "editor"
  if command -v nvim &>/dev/null; then
    run "syncing plugins"
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || warn "plugin sync had issues"
    ok "neovim plugins"
  else
    warn "neovim not installed"
  fi

  printf "\n${G}✓${NC} done\n\n"
}

# ── entrypoint ──────────────────────────────────────────────────────────────────

case "${1:-sync}" in
  sync)      cmd_sync ;;
  uninstall) cmd_uninstall ;;
  *) printf "usage: %s [sync|uninstall]\n" "$0"; exit 1 ;;
esac
