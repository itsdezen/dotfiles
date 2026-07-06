# =============================================================================
# ~/.zshrc — Main Zsh configuration
# Managed by: ~/Developer/dotfiles
# =============================================================================

# ── Path ─────────────────────────────────────────────────────────────────────
# Homebrew shellenv already runs in .zprofile for login shells — only re-run
# here if this is a non-login interactive shell that skipped it.
if ! command -v brew &>/dev/null; then
  # Homebrew (Apple Silicon)
  [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  # Homebrew (Intel)
  [[ -f /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
fi

export PATH="$HOME/.local/bin:$PATH"

# ── zinit (Plugin Manager) ──────────────────────────────────────────────────
# Modern, fast, and flexible zsh plugin manager
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Load zinit
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# ── Plugins ──────────────────────────────────────────────────────────────────

# Git aliases
zinit ice wait lucid
zinit snippet https://github.com/ohmyzsh/ohmyzsh/raw/master/plugins/git/git.plugin.zsh

# Fish-like autosuggestions
zinit ice wait lucid atload'_zsh_autosuggest_start'
zinit light zsh-users/zsh-autosuggestions

# Extra completions for common CLI tools
zinit ice wait lucid blockf
zinit light zsh-users/zsh-completions

# Fast syntax highlighting (better performance)
# Must be loaded last for proper functionality
zinit ice wait lucid atinit'zicompinit; zicdreplay'
zinit light zdharma-continuum/fast-syntax-highlighting

# ── Colors ───────────────────────────────────────────────────────────────────
# Load zsh colors module
autoload -U colors && colors

# BSD ls colors (macOS) - Full warm color scheme (no cyan/blue)
# Format: dir symlink socket pipe exec block char setuid setgid sticky other-writable
export LSCOLORS="DxFxFxDxCxHxHxCbDdDbDd"
#                ││││││││││└┴─ other-writable: yellow bg, brown fg
#                │││││││││└─── sticky: yellow bg, red fg
#                ││││││││└──── setgid: yellow bg, brown fg
#                │││││││└───── setuid: red bg, cyan fg
#                ││││││└────── char device: bold light grey
#                │││││└─────── block device: bold light grey
#                ││││└──────── executable: bold red
#                │││└───────── pipe: bold yellow
#                ││└────────── socket: bold magenta
#                │└─────────── symlink: bold magenta
#                └──────────── directory: bold yellow/amber

# GNU ls colors (if using gls from coreutils) - Full warm theme
export LS_COLORS="di=1;33:ln=1;35:so=1;35:pi=1;33:ex=1;31:bd=1;37:cd=1;37:su=1;41:sg=1;43:tw=1;43:ow=1;33"

# Auto-alias ls with colors for macOS
if ls -G /dev/null &>/dev/null; then
  alias ls='ls -G'
fi

# ── Completion styling ───────────────────────────────────────────────────────
# Reuses $LS_COLORS above, so completion menu colors match `ls` output —
# both ride Ghostty's kanagawa-dragon ANSI palette, no hardcoded hex needed.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case-insensitive
zstyle ':completion:*' menu select                          # arrow-key select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"     # colorize list

# Color for diff command
if diff --color /dev/null{,} &>/dev/null 2>&1; then
  alias diff='diff --color'
fi

# ── History ──────────────────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS  # Don't save duplicate commands
setopt HIST_IGNORE_SPACE     # Don't save commands starting with space
setopt SHARE_HISTORY         # Share history between tabs
setopt EXTENDED_HISTORY      # Save timestamp for each command
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicates first when trimming history
setopt HIST_FIND_NO_DUPS     # Skip duplicates when searching history
setopt HIST_VERIFY           # Expand !! etc. into the buffer before running

# ── Aliases ──────────────────────────────────────────────────────────────────

# ls shortcuts (color already enabled above)
alias ll="ls -lh"
alias la="ls -lah"

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Git shortcuts
# Note: Git plugin provides many aliases like:
# - gst (git status), gd (git diff), ga (git add), gc (git commit)
# - gp (git push), gl (git pull), gco (git checkout), gcb (git checkout -b)
# - glog (git log --oneline --decorate --graph)
alias g="git"

# Development
alias dev="cd ~/Developer"
alias dots="cd ~/Developer/dotfiles"
alias dots-sync="(cd ~/Developer/dotfiles && git pull && ./sync.sh)"
alias v="nvim"
alias codex-local="codex --oss --local-provider ollama --model qwen3:8b"

# Misc
alias zrc="$EDITOR ~/.zshrc"
alias reload="source ~/.zshrc"

# ── mise (Polyglot Version Manager) ─────────────────────────────────────────
# Automatically loads versions from .node-version, .python-version, etc.
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# ── Editor ───────────────────────────────────────────────────────────────────
export EDITOR="nvim"
export VISUAL="$EDITOR"

# ── Starship prompt ─────────────────────────────────────────────────────────
# Fast, minimal, and highly customizable cross-shell prompt
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# ── Ollama ───────────────────────────────────────────────────────────────────
[[ -f "$XDG_CONFIG_HOME/ollama/env" ]] && source "$XDG_CONFIG_HOME/ollama/env"

# ── Startup ──────────────────────────────────────────────────────────────────
if command -v fastfetch &>/dev/null && [[ $COLUMNS -ge 70 ]]; then
  fastfetch
fi

# ── Dotfiles auto-update ─────────────────────────────────────────────────────
# Offers to pull + sync when the dotfiles repo is behind its remote.
# Fetches at most once per $DOTFILES_UPDATE_INTERVAL (default 24h) so shell
# startup stays fast. First install is unaffected — this file only exists
# after the initial ./sync.sh. Run `dotfiles-update` to check manually.
dotfiles-update() {
  local repo="$HOME/Developer/dotfiles"
  [[ -d "$repo/.git" ]] || return 0

  if [[ "$1" != "--force" ]]; then
    local stamp="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-update-check"
    local interval="${DOTFILES_UPDATE_INTERVAL:-86400}"
    [[ -f "$stamp" ]] && (( $(date +%s) - $(stat -f %m "$stamp") < interval )) && return 0
    mkdir -p "${stamp:h}" && touch "$stamp"
  fi

  git -C "$repo" fetch --quiet 2>/dev/null || return 0
  local behind
  behind="$(git -C "$repo" rev-list --count 'HEAD..@{u}' 2>/dev/null)" || return 0
  (( behind > 0 )) || return 0

  local resp
  printf "dotfiles: %d new commit(s) on remote. Pull and sync? [Y/n] " "$behind"
  read -r resp
  [[ -z "$resp" || "$resp" == [Yy] ]] || return 0
  git -C "$repo" pull --ff-only && "$repo/sync.sh"
}
dotfiles-update

# ── Local overrides ──────────────────────────────────────────────────────────
# This file is NOT committed to git — use for machine-specific config
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
