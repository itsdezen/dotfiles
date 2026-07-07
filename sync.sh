#!/usr/bin/env bash
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; BL='\033[0;34m'; P='\033[0;35m'; D='\033[2m'; B='\033[1m'; NC='\033[0m'
ok()      { printf "  ${G}✓${NC} %s\n" "$*"; }
skip()    { printf "  ${D}◎${NC} %s\n" "$*"; }
run()     { printf "  ${D}→${NC} %s\n" "$*"; }
warn()    { printf "  ${Y}!${NC} %s\n" "$*"; }
abort()   {
  [[ -n "$SPIN_PID" ]] && kill "$SPIN_PID" 2>/dev/null; SPIN_PID=""
  printf "\r\033[2K  ${R}✗${NC} %s\n" "$*" >&2
  exit 1
}
section() {
  _section_t=$SECONDS
  printf "\n${P}${B}➤ %s${NC}\n" "$*"
}
section_end() {
  [[ -n "$_section_t" ]] && printf "  ${D}%ds${NC}\n" "$(( SECONDS - _section_t ))"
}

# ── spinner ──────────────────────────────────────────────────────────────────

SPIN_PID=""
_section_t=""
[[ -t 1 ]] && _TTY=true || _TTY=false
trap '[[ -n "$SPIN_PID" ]] && kill "$SPIN_PID" 2>/dev/null' EXIT

spin() {
  if ! $_TTY; then run "$1"; return; fi
  local msg="$1" i=0 frames='|/-\'
  printf "  ${BL}|${NC} %s" "$msg"
  ( while true; do
      printf "\r  ${BL}%s${NC} %s" "${frames:$i:1}" "$msg"
      i=$(( (i+1) % 4 )); sleep 0.05
    done ) &
  SPIN_PID=$!
  disown "$SPIN_PID"
}

spin_ok() {
  if ! $_TTY; then ok "$*"; return; fi
  [[ -n "$SPIN_PID" ]] && kill "$SPIN_PID" 2>/dev/null; SPIN_PID=""
  printf "\r\033[2K  ${G}✓${NC} %s\n" "$*"
}

spin_warn() {
  if ! $_TTY; then warn "$*"; return; fi
  [[ -n "$SPIN_PID" ]] && kill "$SPIN_PID" 2>/dev/null; SPIN_PID=""
  printf "\r\033[2K  ${Y}!${NC} %s\n" "$*"
}

spin_skip() {
  if ! $_TTY; then skip "$*"; return; fi
  [[ -n "$SPIN_PID" ]] && kill "$SPIN_PID" 2>/dev/null; SPIN_PID=""
  printf "\r\033[2K  ${D}◎${NC} %s\n" "$*"
}

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_REPO="https://github.com/itsdezen/dotfiles"
DOTFILES_DIR="$HOME/Developer/dotfiles"
PACKAGES=(zsh nvim aerospace hammerspoon starship ghostty cmux mise fastfetch git ollama superfile btop lazygit claude)

# packages whose target dir mixes static config with app-generated state
# (e.g. claude projects/sessions)
# — always stowed file-by-file so runtime-generated files never land in the repo
NO_FOLD_PACKAGES=(claude cmux)

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
    warn "$pkg — stow failed"
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

# ── bootstrap ───────────────────────────────────────────────────────────────────

cmd_bootstrap() {
  [[ "$(uname)" == "Darwin" ]] || abort "macOS only"

  section "Xcode CLI Tools"
  if ! xcode-select -p &>/dev/null 2>&1; then
    spin "Installing Xcode CLI Tools"
    xcode-select --install 2>/dev/null || true
    until xcode-select -p &>/dev/null 2>&1; do sleep 5; done
    spin_ok "Xcode CLI Tools installed"
  else
    skip "Xcode CLI Tools"
  fi
  section_end

  section "Dotfiles"
  if [[ -d "$DOTFILES_DIR" ]]; then
    skip "Already cloned — $DOTFILES_DIR"
  else
    mkdir -p "$HOME/Developer"
    spin "Cloning dotfiles"
    git clone --quiet "$DOTFILES_REPO" "$DOTFILES_DIR"
    spin_ok "Dotfiles cloned"
  fi
  section_end

  exec "$DOTFILES_DIR/sync.sh"
}

# ── uninstall ───────────────────────────────────────────────────────────────────

cmd_uninstall() {
  printf "${Y}!${NC} Remove all dotfiles symlinks? [y/N] "
  read -r resp
  [[ "$resp" =~ ^[Yy]$ ]] || { ok "aborted"; exit 0; }

  section "Dotfiles"
  command -v stow &>/dev/null || abort "stow not found"
  cd "$DOTFILES"
  for pkg in "${PACKAGES[@]}"; do unstow_pkg "$pkg"; done

  section "Shell"
  ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit"
  if [[ -d "$ZINIT_HOME" ]]; then
    rm -rf "$ZINIT_HOME"
    ok "zinit removed"
  fi

  printf "\n  ${G}✓${NC} done\n"
  warn "Homebrew packages and mise runtimes were not removed"
  warn "To remove Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)\""
}

# ── sync ────────────────────────────────────────────────────────────────────────

cmd_sync() {
  local _t0; _t0=$SECONDS

  # ── system ────────────────────────────────────────────────────────────────────
  section "System"
  [[ "$(uname)" == "Darwin" ]] || abort "macOS only"
  skip "macOS $(sw_vers -productVersion)"

  command -v git  &>/dev/null || abort "git missing — install xcode cli tools: xcode-select --install"
  command -v curl &>/dev/null || abort "curl missing — install xcode cli tools: xcode-select --install"
  skip "git · curl"
  section_end

  # ── homebrew ──────────────────────────────────────────────────────────────────
  section "Homebrew"
  if ! command -v brew &>/dev/null; then
    spin "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >/dev/null
    [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [[ -f /usr/local/bin/brew    ]] && eval "$(/usr/local/bin/brew shellenv)"
    command -v brew &>/dev/null || abort "Homebrew install failed"
    spin_ok "Homebrew installed"
  fi
  skip "Homebrew $(brew --version | head -1 | awk '{print $2}')"
  brew trust nikitabobko/tap >/dev/null 2>&1 || true
  spin "Installing packages"
  local _bout
  _bout=$(brew bundle --file="$DOTFILES/Brewfile" 2>&1) || abort "brew bundle failed: $_bout"
  if echo "$_bout" | grep -qE '^(Installing|Upgrading|Tapping)'; then
    spin_ok "Packages updated"
  else
    spin_skip "Packages up to date"
  fi
  section_end

  # ── dotfiles ──────────────────────────────────────────────────────────────────
  section "Dotfiles"
  command -v stow &>/dev/null || abort "stow not found — run: brew install stow"
  cd "$DOTFILES"
  for pkg in "${PACKAGES[@]}"; do stow_pkg "$pkg"; done
  section_end

  # ── shell ─────────────────────────────────────────────────────────────────────
  section "Shell"
  ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
  if [[ ! -d "$ZINIT_HOME" ]]; then
    spin "Installing zinit"
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone --quiet https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    spin_ok "zinit installed"
  else
    skip "zinit"
  fi
  section_end

  # ── runtimes ──────────────────────────────────────────────────────────────────
  section "Runtimes"
  command -v mise &>/dev/null || abort "mise not found"
  spin "Installing runtimes"
  local _mout
  _mout=$(mise install --yes 2>&1) || abort "mise install failed: $_mout"
  if echo "$_mout" | grep -q "all tools are installed"; then
    spin_skip "Runtimes up to date"
  else
    spin_ok "Runtimes updated"
  fi
  eval "$(mise env)"
  mise ls --current 2>/dev/null | while read -r name version _; do
    [[ -n "$name" ]] && skip "$name $version"
  done
  section_end

  # ── editor ────────────────────────────────────────────────────────────────────
  section "Editor"
  if command -v nvim &>/dev/null; then
    spin "Syncing plugins"
    local nvim_log
    nvim_log="$(nvim --headless "+Lazy! sync" +qa 2>&1)" \
      || { spin_warn "Plugin sync failed"; return; }
    spin_ok "Plugins synced"
  else
    warn "Neovim not found — skipping"
  fi
  section_end

  # ── ai models ─────────────────────────────────────────────────────────────────
  section "AI Models"
  if command -v ollama &>/dev/null; then
    if ! ollama list &>/dev/null 2>&1; then
      spin "Starting Ollama"
      brew services start ollama >/dev/null 2>&1 || true
      local _w=0
      while ! ollama list &>/dev/null 2>&1 && (( _w < 15 )); do
        sleep 1; (( _w++ ))
      done
      spin_ok "Ollama ready"
    fi
    if ollama list 2>/dev/null | grep -q "qwen3:8b"; then
      skip "qwen3:8b"
    else
      spin "Pulling qwen3:8b"
      ollama pull qwen3:8b >/dev/null 2>&1
      spin_ok "qwen3:8b ready"
    fi
  else
    warn "Ollama not found — skipping"
  fi
  section_end

  printf "\n  ${G}✓${NC} done  ${D}$(( SECONDS - _t0 ))s total${NC}\n\n"
}

# ── entrypoint ──────────────────────────────────────────────────────────────────

case "${1:-sync}" in
  sync)      cmd_sync ;;
  bootstrap) cmd_bootstrap ;;
  uninstall) cmd_uninstall ;;
  *) printf "usage: %s [sync|bootstrap|uninstall]\n" "$0"; exit 1 ;;
esac
