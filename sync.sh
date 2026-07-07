#!/usr/bin/env bash
set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; BL='\033[0;34m'; P='\033[38;2;149;127;184m'; D='\033[2m'; B='\033[1m'; NC='\033[0m'
ok()      { printf "  ${G}✓${NC} %s\n" "$*"; }
run()     { printf "  ${D}→${NC} %s\n" "$*"; }
warn()    { printf "  ${Y}!${NC} %s\n" "$*"; }
abort()   {
  [[ -n "$SPIN_PID" ]] && kill "$SPIN_PID" 2>/dev/null; SPIN_PID=""
  printf "\r\033[2K  ${R}✗${NC} %s\n" "$*" >&2
  exit 1
}
section() {
  _section_t=$SECONDS
  printf "\n${P}${B}➤ %s${NC}\n" "$(printf '%s' "$*" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print}')"
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

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(zsh nvim aerospace hammerspoon starship zed ghostty cmux tmux mise fastfetch git ollama superfile btop lazygit claude)

# packages whose target dir mixes static config with app-generated state
# (e.g. zed prompts/themes, claude projects/sessions)
# — always stowed file-by-file so runtime-generated files never land in the repo
NO_FOLD_PACKAGES=(zed claude cmux)

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
  local _t0; _t0=$SECONDS

  # ── system ────────────────────────────────────────────────────────────────────
  section "system"
  [[ "$(uname)" == "Darwin" ]] || abort "macOS only"
  ok "macOS $(sw_vers -productVersion)"

  command -v git  &>/dev/null || abort "git missing — install xcode cli tools: xcode-select --install"
  command -v curl &>/dev/null || abort "curl missing — install xcode cli tools: xcode-select --install"
  ok "git · curl"
  section_end

  # ── homebrew ──────────────────────────────────────────────────────────────────
  section "homebrew"
  if ! command -v brew &>/dev/null; then
    spin "installing homebrew"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >/dev/null
    [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [[ -f /usr/local/bin/brew    ]] && eval "$(/usr/local/bin/brew shellenv)"
    command -v brew &>/dev/null || abort "Homebrew install failed"
    spin_ok "homebrew"
  fi
  ok "Homebrew $(brew --version | head -1 | awk '{print $2}')"
  brew trust nikitabobko/tap >/dev/null 2>&1 || true
  spin "brew bundle"
  local _bout
  _bout=$(brew bundle --file="$DOTFILES/Brewfile" --quiet 2>&1) || abort "brew bundle failed: $_bout"
  spin_ok "packages"
  section_end

  # ── dotfiles ──────────────────────────────────────────────────────────────────
  section "dotfiles"
  command -v stow &>/dev/null || abort "stow not found — run: brew install stow"
  cd "$DOTFILES"
  for pkg in "${PACKAGES[@]}"; do stow_pkg "$pkg"; done
  section_end

  # ── shell ─────────────────────────────────────────────────────────────────────
  section "shell"
  ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
  if [[ ! -d "$ZINIT_HOME" ]]; then
    spin "installing zinit"
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone --quiet https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    spin_ok "zinit"
  else
    ok "zinit"
  fi
  section_end

  # ── runtimes ──────────────────────────────────────────────────────────────────
  section "runtimes"
  command -v mise &>/dev/null || abort "mise not found"
  spin "mise install"
  local _mout
  _mout=$(mise install --yes 2>&1) || abort "mise install failed: $_mout"
  spin_ok "tools installed"
  eval "$(mise env)"
  mise ls --current 2>/dev/null | while read -r name version _; do
    [[ -n "$name" ]] && ok "$name $version"
  done
  section_end

  # ── editor ────────────────────────────────────────────────────────────────────
  section "editor"
  if command -v nvim &>/dev/null; then
    spin "neovim plugins"
    local nvim_log
    nvim_log="$(nvim --headless "+Lazy! sync" +qa 2>&1)" \
      || { spin_warn "plugin sync failed: $nvim_log"; return; }
    spin_ok "neovim plugins"
  else
    warn "neovim not installed"
  fi
  section_end

  # ── ai models ─────────────────────────────────────────────────────────────────
  section "ai models"
  if command -v ollama &>/dev/null; then
    if ! ollama list &>/dev/null 2>&1; then
      spin "starting ollama"
      brew services start ollama >/dev/null 2>&1 || true
      local _w=0
      while ! ollama list &>/dev/null 2>&1 && (( _w < 15 )); do
        sleep 1; (( _w++ ))
      done
      spin_ok "ollama"
    fi
    if ollama list 2>/dev/null | grep -q "qwen3:8b"; then
      ok "qwen3:8b"
    else
      spin "pulling qwen3:8b"
      ollama pull qwen3:8b >/dev/null 2>&1
      spin_ok "qwen3:8b"
    fi
  else
    warn "ollama not found — skipping models"
  fi
  section_end

  printf "\n${G}  ✓ done${NC}  ${D}$(( SECONDS - _t0 ))s total${NC}\n\n"
}

# ── entrypoint ──────────────────────────────────────────────────────────────────

case "${1:-sync}" in
  sync)      cmd_sync ;;
  uninstall) cmd_uninstall ;;
  *) printf "usage: %s [sync|uninstall]\n" "$0"; exit 1 ;;
esac
