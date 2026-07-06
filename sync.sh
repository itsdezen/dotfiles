#!/usr/bin/env bash
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; D='\033[2m'; B='\033[1m'; NC='\033[0m'
ok()      { printf "  ${G}✓${NC} %s\n" "$*"; }
run()     { printf "  ${D}→${NC} %s\n" "$*"; }
warn()    { printf "  ${Y}!${NC} %s\n" "$*"; }
abort()   { printf "  ${R}✗${NC} %s\n" "$*" >&2; exit 1; }
section() { printf "\n${B}%s${NC}\n" "$*"; }

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(zsh nvim aerospace hammerspoon starship zed ghostty cmux tmux mise fastfetch git ollama superfile btop lazygit claude)

# packages whose target dir mixes static config with app-generated state
# (e.g. zed prompts/themes, claude projects/sessions) — always stowed file-by-file
# so runtime-generated files never land inside the repo
NO_FOLD_PACKAGES=(zed claude)

# ── stow helpers ────────────────────────────────────────────────────────────────

is_no_fold() {
  local pkg="$1" p
  for p in "${NO_FOLD_PACKAGES[@]}"; do
    [[ "$p" == "$pkg" ]] && return 0
  done
  return 1
}

stow_pkg() {
  local pkg="$1"
  [[ -d "$DOTFILES/$pkg" ]] || { warn "package not found: $pkg"; return; }
  local fold_flag=""
  is_no_fold "$pkg" && fold_flag="--no-folding"
  # $fold_flag intentionally unquoted: word-splits away when empty (bash 3.2 on
  # macOS can't safely expand an empty array under set -u)
  stow -n -t "$HOME" -R $fold_flag "$pkg" 2>&1 \
    | perl -ne '
        if (/existing target is not owned by stow: (.+)$/) { print "$1\n" }
        elsif (/existing target is stowed to a different package: (.+?) => /) { print "$1\n" }
        elsif (/cannot stow .* over existing (?:directory )?target (.+?)(?: since\b|$)/) { print "$1\n" }
      ' \
    | while IFS= read -r conflict; do
        [[ -n "$conflict" ]] || continue
        local target="$HOME/$conflict"
        [[ "$target" == "$HOME/"* ]] || continue
        rm -rf "$target"
      done \
    || true
  if stow -t "$HOME" -R $fold_flag "$pkg" 2>/dev/null; then
    ok "$pkg"
  else
    warn "$pkg stow failed"
  fi
}

unstow_pkg() {
  local pkg="$1"
  [[ -d "$DOTFILES/$pkg" ]] || return
  local fold_flag=""
  is_no_fold "$pkg" && fold_flag="--no-folding"
  if stow -t "$HOME" -D $fold_flag "$pkg" 2>/dev/null; then
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

  command -v git  &>/dev/null || abort "git missing — install xcode cli tools: xcode-select --install"
  command -v curl &>/dev/null || abort "curl missing — install xcode cli tools: xcode-select --install"
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
  run "installing tools from mise config"
  mise install --yes >/dev/null
  eval "$(mise env)"
  mise ls --current 2>/dev/null | while read -r name version _; do
    [[ -n "$name" ]] && ok "$name $version"
  done

  # ── editor ────────────────────────────────────────────────────────────────────
  section "editor"
  if command -v nvim &>/dev/null; then
    run "syncing plugins"
    local nvim_log
    nvim_log="$(nvim --headless "+Lazy! sync" +qa 2>&1)" \
      || { warn "plugin sync failed"; warn "$nvim_log"; return; }
    ok "neovim plugins"
  else
    warn "neovim not installed"
  fi

  # ── ai models ─────────────────────────────────────────────────────────────────
  section "ai models"
  if command -v ollama &>/dev/null; then
    if ! ollama list &>/dev/null 2>&1; then
      run "starting ollama"
      brew services start ollama >/dev/null 2>&1 || true
      local _w=0
      while ! ollama list &>/dev/null 2>&1 && (( _w < 15 )); do
        sleep 1; (( _w++ ))
      done
    fi
    if ollama list 2>/dev/null | grep -q "qwen3:8b"; then
      ok "qwen3:8b"
    else
      run "pulling qwen3:8b (may take a while)"
      ollama pull qwen3:8b
      ok "qwen3:8b"
    fi
  else
    warn "ollama not found — skipping models"
  fi

  printf "\n${G}✓${NC} done\n\n"
}

# ── entrypoint ──────────────────────────────────────────────────────────────────

case "${1:-sync}" in
  sync)      cmd_sync ;;
  uninstall) cmd_uninstall ;;
  *) printf "usage: %s [sync|uninstall]\n" "$0"; exit 1 ;;
esac
