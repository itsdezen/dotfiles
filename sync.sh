#!/bin/sh
# shellcheck shell=bash
# /bin/sh on macOS is bash 3.2 in POSIX mode — the canonical interpreter here, so
# `./sync.sh` and `sh sync.sh` are identical. Stick to syntax its POSIX parser
# accepts (no process substitution < <(...)); herestrings, arrays, and [[ ]] run
# fine, so linting stays in bash dialect and `sh -n sync.sh` is the parity check.
set -euo pipefail

# ── flags ──────────────────────────────────────────────────────────────────────

_VERBOSE=false
_CMD="sync"
usage() {
  cat <<EOF
usage: $0 [-v|--verbose] [--no-color] [sync|bootstrap|uninstall]

  sync              sync everything (default)
  bootstrap         fresh machine: Xcode CLI tools → clone → sync
  uninstall         remove dotfile symlinks, zinit and TPM
  -v, --verbose     list every item: runtime inventory, long change lists
  --no-color        plain output (NO_COLOR is honoured as well)
EOF
}
for _arg in ${1+"$@"}; do
  case "$_arg" in
    -v|--verbose) _VERBOSE=true ;;
    --no-color)   NO_COLOR=1 ;;
    -h|--help)    usage; exit 0 ;;
    sync|bootstrap|uninstall) _CMD="$_arg" ;;
    *) usage >&2; exit 1 ;;
  esac
done

# ── terminal ───────────────────────────────────────────────────────────────────

if [[ -t 1 ]]; then _TTY=true; else _TTY=false; fi
# colours are a tty affordance: piped output stays free of escape codes, and
# NO_COLOR / TERM=dumb are respected
if $_TTY && [[ -z "${NO_COLOR:-}" ]] && [[ "${TERM:-}" != "dumb" ]]; then
  G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; BL='\033[0;34m'; P='\033[0;35m'; D='\033[2m'; B='\033[1m'; NC='\033[0m'
else
  G=''; Y=''; R=''; BL=''; P=''; D=''; B=''; NC=''
fi

# ── state ──────────────────────────────────────────────────────────────────────
#
# One status vocabulary for every step, worst-wins per section:
#   ✓ ok (something changed)   ◎ skip (nothing to do)   ! warn   ✗ fail
# `step` opens a live spinner, `step_end` closes it and records the outcome; a
# section is printed once, at section_end, as a single line plus its items. That
# keeps output compact and makes a half-finished run impossible to misreport.

_STEP_OPEN=0
_STEP_MSG=""
_SPIN_PID=""
_SEC_NAME=""
_SEC_T=0
_SEC_STATUS=skip
_SEC_SUM=""
_SEC_ITEMS=()
_SEC_EXTRA=()
_MAX_ITEMS=10
N_CHANGED=0; N_NOOP=0; N_WARN=0; N_FAIL=0
_T0=$SECONDS

ok()   { printf "  ${G}✓${NC} %s\n" "$*"; }
skip() { printf "  ${D}◎${NC} %s\n" "$*"; }
run()  { printf "  ${D}→${NC} %s\n" "$*"; }
info() { printf "  ${BL}·${NC} %s\n" "$*"; }
warn() { printf "  ${Y}!${NC} %s\n" "$*"; }

_spin_stop() {
  if [[ -n "$_SPIN_PID" ]]; then
    kill "$_SPIN_PID" 2>/dev/null || true
    _SPIN_PID=""
  fi
}

# close the live line, whatever opened it
_live_clear() {
  _spin_stop
  if (( _STEP_OPEN )); then
    $_TTY && printf "\r\033[2K"
    _STEP_OPEN=0
  fi
}

# a failing step must never leave the spinner running or the run mislabelled
_on_exit() {
  if (( _STEP_OPEN )); then
    _live_clear
    printf "  ${R}✗${NC} %s\n" "${_SEC_NAME:+$_SEC_NAME · }${_STEP_MSG} — interrupted"
  fi
}
trap '_on_exit' EXIT

abort() {
  _live_clear
  printf "  ${R}✗${NC} %s\n" "${_SEC_NAME:+$_SEC_NAME · }$*"
  exit 1
}

# ── step / section rendering ───────────────────────────────────────────────────

step() {
  _STEP_MSG="$*"; _STEP_OPEN=1
  $_TTY || return 0
  local i=0 frames='|/-\'
  printf "  ${BL}|${NC} %s" "$*"
  ( while true; do
      printf "\r  ${BL}%s${NC} %s" "${frames:$i:1}" "$*"
      i=$(( (i+1) % 4 )); sleep 0.08
    done ) &
  _SPIN_PID=$!
  disown "$_SPIN_PID" 2>/dev/null || true
}

_sec_status() {
  case "$1" in
    fail) _SEC_STATUS=fail ;;
    warn) [[ "$_SEC_STATUS" == fail ]] || _SEC_STATUS=warn ;;
    ok)   [[ "$_SEC_STATUS" == fail || "$_SEC_STATUS" == warn ]] || _SEC_STATUS=ok ;;
    *)    : ;;
  esac
}

_sec_sum() {
  if [[ -n "$_SEC_SUM" ]]; then _SEC_SUM="$_SEC_SUM · $1"; else _SEC_SUM="$1"; fi
}

step_end() {
  local st="$1"; shift
  _live_clear
  case "$st" in
    ok)   N_CHANGED=$(( N_CHANGED + 1 )) ;;
    skip) N_NOOP=$(( N_NOOP + 1 )) ;;
    warn) N_WARN=$(( N_WARN + 1 )) ;;
    fail) N_FAIL=$(( N_FAIL + 1 )) ;;
  esac
  _sec_status "$st"
  [[ -n "$*" ]] && _sec_sum "$*"
  return 0
}

spin()      { step "$@"; }
spin_ok()   { step_end ok "$@"; }
spin_skip() { step_end skip "$@"; }
spin_warn() { step_end warn "$@"; }
spin_fail() { step_end fail "$@"; }

section() {
  _SEC_NAME="$*"
  _SEC_T=$SECONDS
  _SEC_STATUS=skip
  _SEC_SUM=""
  _SEC_ITEMS=()
  _SEC_EXTRA=()
}

# Colors reach `line` as escape *text* (that is how they are defined), so they
# must go through %b — %s would store the literal "\033[1;33m" and print it raw.
_item() {
  local line
  printf -v line "    %b%s %s%b" "$1" "$2" "$3" "$NC"
  if [[ -n "$_SEC_NAME" ]]; then _SEC_ITEMS+=("$line"); else printf "%s\n" "$line"; fi
}

item_new()  { _item "$G"  '+' "$*"; }
item_upd()  { _item "$Y"  '↑' "$*"; }
item_rm()   { _item "$R"  '-' "$*"; }
item_note() { _item "$BL" '·' "$*"; }

# verbose-only detail (runtime inventory) — never truncated by the item cap
_item_extra() {
  local line
  printf -v line "    %b· %s%b" "$BL" "$*" "$NC"
  if [[ -n "$_SEC_NAME" ]]; then _SEC_EXTRA+=("$line"); else printf "%s\n" "$line"; fi
}

_flush_items() {
  local line i=0 n=${#_SEC_ITEMS[@]}
  for line in ${_SEC_ITEMS[@]+"${_SEC_ITEMS[@]}"}; do
    i=$(( i + 1 ))
    if ! $_VERBOSE && (( i > _MAX_ITEMS )); then
      printf "    ${D}… +%d more · use -v${NC}\n" $(( n - _MAX_ITEMS ))
      break
    fi
    printf "%s\n" "$line"
  done
  if $_VERBOSE; then
    for line in ${_SEC_EXTRA[@]+"${_SEC_EXTRA[@]}"}; do printf "%s\n" "$line"; done
  fi
  _SEC_ITEMS=(); _SEC_EXTRA=()
}

section_end() {
  [[ -n "$_SEC_NAME" ]] || return 0
  local d=$(( SECONDS - _SEC_T )) glyph color sum
  case "$_SEC_STATUS" in
    fail) glyph='✗'; color="$R" ;;
    warn) glyph='!'; color="$Y" ;;
    ok)   glyph='✓'; color="$G" ;;
    *)    glyph='◎'; color="$D" ;;
  esac
  sum="${_SEC_SUM:--}"
  # no right-aligned timer column: padding every line out to a shared column
  # costs ~15 columns of nothing on the common short line. The duration trails
  # the summary instead, so a line is only as wide as what it says
  # section lines sit one indent step in, so they line up with the step and item
  # rows below them instead of hanging off the left margin
  printf "  ${P}${B}➤${NC} %-15s ${color}${glyph}${NC} %s" "$_SEC_NAME" "$sum"
  if (( d >= 1 )); then printf "  ${D}%ds${NC}" "$d"; fi
  printf "\n"
  _flush_items
  _SEC_NAME=""
  return 0
}

# final tally; the exit code carries the outcome, so a broken run is not silent
finish() {
  local d=$(( SECONDS - _T0 )) parts=""
  if (( N_CHANGED > 0 )); then parts="$parts · $N_CHANGED changed"; fi
  if (( N_NOOP > 0 ));    then parts="$parts · $N_NOOP no-op"; fi
  if (( N_WARN > 0 ));    then parts="$parts · $N_WARN warning"; fi
  if (( N_FAIL > 0 )); then
    printf "\n  ${R}✗${NC} failed in ${d}s · $N_FAIL failed${parts}\n\n"
    exit 1
  fi
  printf "\n  ${G}✓${NC} done in ${d}s${parts}\n\n"
}

_plural() {
  if [[ "$1" == 1 ]]; then printf '%s %s' "$1" "$2"; else printf '%s %ss' "$1" "$2"; fi
}

_join() {
  local out="" a
  for a in "$@"; do
    if [[ -n "$a" ]]; then out="${out:+$out · }$a"; fi
  done
  printf '%s' "$out"
}

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_REPO="https://github.com/itsdezen/dotfiles"
DOTFILES_DIR="$HOME/Developer/dotfiles"
PACKAGES=(zsh mise git starship nvim ghostty superfile btop opencode herdr tili tmux)

# packages whose target dir mixes static config with app-generated state
# (herdr logs/sockets/session.json, btop themes/, superfile theme/)
# — always stowed file-by-file so runtime-generated files never land in the repo
# opencode is folded instead: its settings writer does temp-file + rename, which
# replaces a file-level symlink with a real file. Folding the config directory
# makes those rewrites land on the tracked cli.json; runtime files are gitignored.
NO_FOLD_PACKAGES=(herdr btop superfile)

# ── stow helpers ────────────────────────────────────────────────────────────────

# per-run stow results, aggregated by cmd_sync into a single summary line
STOW_OK=()
STOW_FAIL=()
STOW_REPLACED=()
PRUNED=()

is_no_fold() {
  local pkg="$1" p
  for p in "${NO_FOLD_PACKAGES[@]}"; do
    [[ "$p" == "$pkg" ]] && return 0
  done
  return 1
}

is_package() {
  local pkg="$1" p
  for p in "${PACKAGES[@]}"; do
    [[ "$p" == "$pkg" ]] && return 0
  done
  return 1
}

stow_pkg() {
  local pkg="$1"
  [[ -d "$DOTFILES/$pkg" ]] || { STOW_FAIL+=("$pkg"); return 0; }
  local fold_flag=""
  is_no_fold "$pkg" && fold_flag="--no-folding"
  # $fold_flag intentionally unquoted: word-splits away when empty (bash 3.2 on
  # macOS can't safely expand an empty array under set -u)
  local conflicts
  conflicts=$(stow -n -t "$HOME" -R $fold_flag "$pkg" 2>&1 \
    | perl -ne '
        if (/existing target is not owned by stow: (.+)$/) { print "$1\n" }
        elsif (/existing target is stowed to a different package: (.+?) => /) { print "$1\n" }
        elsif (/cannot stow .* over existing (?:directory )?target (.+?)(?: since\b|$)/) { print "$1\n" }
      ') || true
  while IFS= read -r conflict; do
    [[ -n "$conflict" ]] || continue
    local target="$HOME/$conflict"
    [[ "$target" == "$HOME/"* ]] || continue
    rm -rf "$target"
  done <<<"$conflicts"
  if stow -t "$HOME" -R $fold_flag "$pkg" 2>/dev/null; then
    STOW_OK+=("$pkg")
    while IFS= read -r conflict; do
      [[ -n "$conflict" ]] || continue
      STOW_REPLACED+=("$conflict")
    done <<<"$conflicts"
  else
    STOW_FAIL+=("$pkg")
  fi
  return 0
}

unstow_pkg() {
  local pkg="$1"
  [[ -d "$DOTFILES/$pkg" ]] || return 0
  local fold_flag=""
  is_no_fold "$pkg" && fold_flag="--no-folding"
  stow -t "$HOME" -D $fold_flag "$pkg" 2>/dev/null
}

# ── prune ───────────────────────────────────────────────────────────────────────

# `stow -D` can only unwind a package that still exists on disk, so dropping one
# from PACKAGES — or renaming/deleting a tracked file — strands its links in
# $HOME as dangling symlinks (`stow` keeps no manifest to clean up later). Walk
# the only two places packages ever link into — $HOME itself and ~/.config — and
# drop links back into this repo that are broken or owned by a delisted package.

# lexical (symlink-free) path normalisation — collapses //, /./ and /.., so a
# link and $DOTFILES compare equal even when one is spelled with a trailing or
# doubled slash (e.g. $TMPDIR-derived paths)
prune_canon() {
  printf '%s' "$1" | perl -e '
    local $/; my $p = <STDIN>; chomp $p;
    my @parts;
    for my $c (split m{/}, $p) {
      next if $c eq "" || $c eq ".";
      $c eq ".." ? pop(@parts) : push(@parts, $c);
    }
    print "/", join("/", @parts);
  '
}

# 12 packages × 1 perl each was the slowest silent part of a run: canon() the
# whole link list in one process instead, keyed by the raw link path
prune_resolve_all() {
  local links="$1" repo_a="$2" repo_b="$3"
  LINKS="$links" REPO_A="$repo_a" REPO_B="$repo_b" perl -e '
    my $home = $ENV{HOME} // "";
    my %raw;
    for my $l (split /\n/, ($ENV{LINKS} // "")) {
      next if $l eq "";
      my $t = readlink($l);
      next unless defined $t;
      my $abs = $t =~ m{^/} ? $t : (($l =~ m{^(.*)/[^/]*$}) ? "$1/$t" : "/$t");
      my @parts;
      for my $c (split m{/}, $abs) {
        next if $c eq "" || $c eq ".";
        $c eq ".." ? pop(@parts) : push(@parts, $c);
      }
      $raw{$l} = "/" . join("/", @parts);
    }
    for my $l (sort keys %raw) {
      print "$l\t$raw{$l}\n";
    }
  '
}

# a delisted package leaves its now-empty ~/.config/<pkg>/ behind after its last
# link is pruned — unwrap those, but never touch ~/.config itself
prune_empty_dirs() {
  local dir="$1" root="$HOME/.config"
  while [[ "$dir" == "$root/"* && -d "$dir" && -z "$(ls -A "$dir" 2>/dev/null)" ]]; do
    rmdir "$dir" 2>/dev/null || break
    dir="$(dirname "$dir")"
  done
}

prune_links() {
  local link abs owner links repo_a repo_b
  links="$( { find "$HOME" -maxdepth 1 -type l
              find "$HOME/.config" -type l
            } 2>/dev/null )"
  [[ -n "$links" ]] || return 0
  repo_a="$(prune_canon "$DOTFILES")"
  repo_b="$(prune_canon "$DOTFILES_DIR")"
  while IFS=$'\t' read -r link abs; do
    [[ -n "$link" && -L "$link" ]] || continue
    case "$abs" in
      "$repo_a"/*) owner="${abs#"$repo_a"/}" ;;
      "$repo_b"/*) owner="${abs#"$repo_b"/}" ;;
      *) continue ;;
    esac
    owner="${owner%%/*}"
    # keep it only while the link is live and its package is still listed
    if [[ -e "$link" ]] && is_package "$owner"; then continue; fi
    rm -f "$link"
    PRUNED+=("${link#"$HOME"/}")
    prune_empty_dirs "$(dirname "$link")"
  done <<<"$(prune_resolve_all "$links" "$repo_a" "$repo_b")"
  return 0
}

# ── mise helpers ────────────────────────────────────────────────────────────────

# current toolset as tab-separated `name<TAB>version` lines. The JSON form is the
# stable one: the text table truncates versions containing spaces (rust reports
# "stable (symlink)"), which would desync the before/after diff.
mise_snapshot() {
  # `|| true`: a broken snapshot must never be fatal under set -e
  mise ls --current --json 2>/dev/null \
    | jq -r 'to_entries[] | "\(.key)\t\(.value[0].version)"' 2>/dev/null || true
}

# ── bootstrap ───────────────────────────────────────────────────────────────────

cmd_bootstrap() {
  [[ "$(uname)" == "Darwin" ]] || abort "macOS only"

  section "Xcode CLI Tools"
  if ! xcode-select -p &>/dev/null 2>&1; then
    step "Installing Xcode CLI Tools"
    xcode-select --install 2>/dev/null || true
    local _waited=0
    until xcode-select -p &>/dev/null 2>&1; do
      sleep 5; _waited=$(( _waited + 5 ))
      (( _waited >= 1200 )) && abort "still waiting after 20 min — finish the installer dialog, then re-run"
    done
    if (( _waited > 0 )); then spin_ok "installed (${_waited}s)"; else spin_ok "installed"; fi
  else
    spin_skip "already installed"
  fi
  section_end

  section "Dotfiles"
  if [[ -d "$DOTFILES_DIR" ]]; then
    spin_skip "already cloned"
  else
    step "Cloning dotfiles"
    mkdir -p "$HOME/Developer"
    git clone --quiet "$DOTFILES_REPO" "$DOTFILES_DIR" || abort "clone failed: $DOTFILES_REPO"
    spin_ok "cloned to $DOTFILES_DIR"
  fi
  section_end

  exec "$DOTFILES_DIR/sync.sh"
}

# ── uninstall ───────────────────────────────────────────────────────────────────

cmd_uninstall() {
  printf "${Y}!${NC} Remove all dotfiles symlinks? [y/N] "
  read -r resp
  $_TTY || printf "\n"
  [[ "$resp" =~ ^[Yy]$ ]] || { ok "aborted"; exit 0; }

  section "Dotfiles"
  command -v stow &>/dev/null || abort "stow not found"
  cd "$DOTFILES"
  local n=0 failed=0 pkg
  step "Unstowing ${#PACKAGES[@]} packages"
  for pkg in "${PACKAGES[@]}"; do
    if unstow_pkg "$pkg"; then n=$(( n + 1 )); else failed=$(( failed + 1 )); item_rm "$pkg"; fi
  done
  if (( failed == 0 )); then
    spin_ok "$(_plural "$n" package) unstowed"
  else
    spin_fail "$n/${#PACKAGES[@]} unstowed — $failed failed"
  fi
  section_end

  section "Shell"
  ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit"
  if [[ -d "$ZINIT_HOME" ]]; then
    step "Removing zinit"
    rm -rf "$ZINIT_HOME"
    spin_ok "zinit removed"
  else
    spin_skip "zinit not installed"
  fi
  section_end

  section "tmux plugins"
  if [[ -d "$HOME/.tmux/plugins" ]]; then
    step "Removing TPM and plugins"
    rm -rf "$HOME/.tmux/plugins"
    spin_ok "TPM removed"
  else
    spin_skip "TPM not installed"
  fi
  section_end

  warn "Homebrew packages and mise runtimes were not removed"
  warn "To remove Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)\""
  finish
}

# ── sync ────────────────────────────────────────────────────────────────────────

cmd_sync() {
  _T0=$SECONDS
  STOW_OK=(); STOW_FAIL=(); STOW_REPLACED=(); PRUNED=()
  N_CHANGED=0; N_NOOP=0; N_WARN=0; N_FAIL=0

  # ── system ────────────────────────────────────────────────────────────────────
  section "System"
  [[ "$(uname)" == "Darwin" ]] || abort "macOS only"
  command -v git  &>/dev/null || abort "git missing — install xcode cli tools: xcode-select --install"
  command -v curl &>/dev/null || abort "curl missing — install xcode cli tools: xcode-select --install"
  spin_skip "macOS $(sw_vers -productVersion) · git · curl"
  section_end

  # ── homebrew ──────────────────────────────────────────────────────────────────
  section "Homebrew"
  if ! command -v brew &>/dev/null; then
    step "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >/dev/null
    [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
    [[ -f /usr/local/bin/brew    ]] && eval "$(/usr/local/bin/brew shellenv)"
    command -v brew &>/dev/null || abort "Homebrew install failed"
    spin_ok "installed"
  fi
  # pin brew to stable tags: dev commands (e.g. `brew trust`) enable developer
  # mode, which makes `brew update` track the beta `main` branch
  export HOMEBREW_UPDATE_TO_TAG=1
  local _hb_updated=true _hbout _hb_repo _hb_tag _hb_ver
  step "Updating Homebrew"
  brew tap itsdezen/tap &>/dev/null || true
  brew trust itsdezen/tap &>/dev/null || true
  brew developer off &>/dev/null || true
  _hbout=$(brew update 2>&1) || _hb_updated=false
  _hb_repo="$(brew --repository)"
  _hb_tag="$(git -C "$_hb_repo" tag --list --sort=-version:refname | grep -m1 -E '^[0-9]+\.[0-9]+\.[0-9]+$' || true)"
  if [[ -n "$_hb_tag" ]]; then
    git -C "$_hb_repo" checkout --quiet "$_hb_tag" &>/dev/null || true
  fi
  _hb_ver="$(brew --version | head -1 | awk '{print $2}')"
  # `brew update` is a no-op most runs; report that as such instead of always
  # claiming an update (state precision, not just cosmetics)
  if ! $_hb_updated; then
    spin_warn "update failed $_hb_ver"
  elif grep -qi "already up-to-date" <<<"$_hbout"; then
    spin_skip "$_hb_ver"
  else
    spin_ok "updated $_hb_ver"
  fi

  # `brew bundle` can make sudo ask for a password: a cask with a pkg installer,
  # or one replacing an /Applications bundle owned by root. sudo writes that
  # prompt straight to /dev/tty (not stderr), i.e. wherever the cursor happens to
  # be — so it needs a line that is already terminated, never the spinner's line,
  # or the two overwrite each other. Only casks can trigger sudo (formulae
  # install under the user's own prefix), so gate on pending cask work:
  # authenticate up front on a clean line, then spin as usual.
  local _cask_tmp _pending_casks
  _cask_tmp="$(mktemp -d)"
  brew list --cask 2>/dev/null | sort >"$_cask_tmp/installed" || true
  # Brewfile tokens can be tap-qualified (itsdezen/tap/foo) while `brew list`
  # prints the bare token, so strip the tap prefix before diffing
  grep -E '^cask ' "$DOTFILES/Brewfile" \
    | sed -E 's/^cask "([^"]+)".*/\1/; s|.*/||' | sort >"$_cask_tmp/wanted" || true
  _pending_casks="$(comm -13 "$_cask_tmp/installed" "$_cask_tmp/wanted" 2>/dev/null || true)"
  # bundle upgrades auto-updating casks only with --greedy (Homebrew/bundle/
  # cask.rb: upgrading?), which sync never passes, so keep them out of this list
  _pending_casks="$_pending_casks $(brew outdated --cask --quiet 2>/dev/null || true)"
  rm -rf "$_cask_tmp"
  if $_TTY && [[ -n "${_pending_casks//[[:space:]]/}" ]]; then
    printf "  ${D}→${NC} Checking packages · cask work may ask for your password\n"
    SUDO_PROMPT="    Password: " sudo -v || true
  fi
  step "Checking packages"
  local _btmp _bout _bundle_ok=true _stale_cask
  _btmp="$(mktemp)"
  _bout=$(SUDO_PROMPT="    Password: " brew bundle --file="$DOTFILES/Brewfile" -v 2>"$_btmp") || _bundle_ok=false
  if ! $_bundle_ok; then
    # a Brewfile cask rename (e.g. claude-code -> claude-code@latest) leaves the
    # old cask installed and conflicting; `brew bundle cleanup` would remove it,
    # but bundle aborts before reaching cleanup, so retry once after clearing it
    _bout="$_bout
$(cat "$_btmp")"
    _stale_cask=$(grep -oE "conflicts with '[^']+'" <<<"$_bout" | head -1 | sed -E "s/conflicts with '(.+)'/\1/")
    if [[ -n "$_stale_cask" ]] && ! grep -q "cask \"$_stale_cask\"" "$DOTFILES/Brewfile" && brew list --cask "$_stale_cask" &>/dev/null; then
      item_note "removing stale cask $_stale_cask (renamed in Brewfile)"
      brew uninstall --cask "$_stale_cask" &>/dev/null || true
      : >"$_btmp"
      _bout=$(SUDO_PROMPT="    Password: " brew bundle --file="$DOTFILES/Brewfile" -v 2>"$_btmp") || _bundle_ok=false
    fi
    if ! $_bundle_ok; then
      spin_fail "brew bundle failed"
      section_end
      printf '%s\n' "$_bout" | tail -n 8 | while IFS= read -r _line; do
        printf "    ${D}%s${NC}\n" "$_line"
      done
      rm -f "$_btmp"
      finish
    fi
  fi
  rm -f "$_btmp"
  # depends on exact wording of `brew bundle -v` output — a Homebrew wording
  # change silently drops install/upgrade counts back to "up to date"
  local _using _inst _upg _n_inst=0 _n_upg=0
  _using=$(grep -cE '^Using ' <<<"$_bout" || true)
  _inst=$(grep -E '^Installing .+\. It is not currently installed\.$' <<<"$_bout" \
    | sed -E 's/^Installing ([^ ]+) ([a-zA-Z_-]+).*/\1\t\2/' || true)
  _upg=$(grep -E '^Upgrading .+\. It is installed but .*up-to-date\.$' <<<"$_bout" \
    | sed -E 's/^Upgrading ([^ ]+) ([a-zA-Z_-]+).*/\1\t\2/' || true)
  while IFS=$'\t' read -r name kind; do
    [[ -z "$name" ]] && continue
    _n_inst=$(( _n_inst + 1 ))
    if [[ "$kind" == "tap" ]]; then item_new "tap $name"; elif [[ "$kind" == "cask" ]]; then item_new "$name (cask)"; else item_new "$name"; fi
  done <<<"$_inst"
  while IFS=$'\t' read -r name kind; do
    [[ -z "$name" ]] && continue
    _n_upg=$(( _n_upg + 1 ))
    if [[ "$kind" == "cask" ]]; then item_upd "$name (cask)"; else item_upd "$name"; fi
  done <<<"$_upg"
  if (( _n_inst + _n_upg > 0 )); then
    spin_ok "$(_join "$(_plural "$_n_inst" package) installed" "$(_plural "$_n_upg" package) upgraded")"
  else
    spin_skip "$_using current"
  fi
  step "Checking cleanup candidates"
  local _cout _cleanup_list
  _cout=$(brew bundle cleanup --file="$DOTFILES/Brewfile" 2>&1) || true
  _cleanup_list=$(awk '
      /^Would uninstall casks:/    { sect="cask"; next }
      /^Would uninstall formulae:/ { sect="formula"; next }
      /^Would untap:/              { sect="tap"; next }
      /^Would /                    { sect=""; next }
      # package names never contain spaces — NF==1 drops trailing prose
      # (e.g. the "Run `brew bundle cleanup --force`" hint brew appends)
      sect && NF == 1 { print sect"\t"$0 }
    ' <<<"$_cout")
  # formulae pulled in as transitive deps of an unlisted formula (e.g. every
  # library ffmpeg-full links against) are noise — only surface leaves
  # (`brew leaves`): formulae nothing else installed depends on
  if grep -q $'^formula\t' <<<"$_cleanup_list"; then
    local _leaves _filtered kind name
    _leaves=$(brew leaves)
    _filtered=""
    while IFS=$'\t' read -r kind name; do
      [[ -z "$name" ]] && continue
      if [[ "$kind" != "formula" ]] || grep -Fxq "$name" <<<"$_leaves"; then
        _filtered+="$kind"$'\t'"$name"$'\n'
      fi
    done <<<"$_cleanup_list"
    _cleanup_list="${_filtered%$'\n'}"
  fi
  if [[ -n "$_cleanup_list" ]]; then
    local _rm_formulae _rm_casks _rm_taps _n_rm=0
    while IFS=$'\t' read -r kind name; do
      [[ -z "$name" ]] && continue
      _n_rm=$(( _n_rm + 1 ))
      if [[ "$kind" == "cask" ]]; then item_rm "$name (cask)"; elif [[ "$kind" == "formula" ]]; then item_rm "$name"; else item_rm "$name (tap)"; fi
    done <<<"$_cleanup_list"
    # NOT `brew bundle cleanup --force` — that acts on the unfiltered list
    # (every transitive dep too), not just the leaves shown above
    _rm_formulae=$(awk -F'\t' '$1=="formula"{printf "%s ", $2}' <<<"$_cleanup_list")
    _rm_casks=$(awk -F'\t' '$1=="cask"{printf "%s ", $2}' <<<"$_cleanup_list")
    _rm_taps=$(awk -F'\t' '$1=="tap"{printf "%s ", $2}' <<<"$_cleanup_list")
    spin_warn "$(_plural "$_n_rm" package) not in Brewfile"
    if [[ -n "$_rm_formulae" ]]; then item_note "brew uninstall ${_rm_formulae% } && brew autoremove"; fi
    if [[ -n "$_rm_casks"    ]]; then item_note "brew uninstall --cask ${_rm_casks% }"; fi
    if [[ -n "$_rm_taps"     ]]; then item_note "brew untap ${_rm_taps% }"; fi
  else
    spin_skip "clean"
  fi
  section_end

  # ── code signing ─────────────────────────────────────────────────────────────
  # newly poured Homebrew bottles are ad-hoc signed; on some macOS versions the
  # kernel flags them as tainted and SIGKILLs them on first run — re-sign locally
  # to clear it (see: opencode getting killed right after a fresh install)
  local _touched_formulae
  _touched_formulae=$(printf '%s\n%s\n' "$_inst" "$_upg" | grep -E $'\tformula$' | cut -f1 || true)
  if [[ -n "$_touched_formulae" ]]; then
    section "Code signing"
    local _fixed=0 _bad=0 _checked=0
    step "Checking signatures"
    while read -r name; do
      [[ -z "$name" ]] && continue
      local _bin_dir _f _spctl_out
      _bin_dir="$(brew --prefix "$name" 2>/dev/null)/bin"
      [[ -d "$_bin_dir" ]] || continue
      for _f in "$_bin_dir"/*; do
        [[ -f "$_f" && -x "$_f" ]] || continue
        file "$_f" 2>/dev/null | grep -q "Mach-O" || continue
        _checked=$(( _checked + 1 ))
        _spctl_out=$(spctl -a -vv "$_f" 2>&1) || true
        [[ "$_spctl_out" == *"invalid signature"* ]] || continue
        if codesign --force -s - "$_f" &>/dev/null; then
          item_upd "re-signed $name ($(basename "$_f"))"
          _fixed=$(( _fixed + 1 ))
        else
          item_note "could not re-sign $name ($(basename "$_f")) — it may fail to run"
          _bad=$(( _bad + 1 ))
        fi
      done
    done <<<"$_touched_formulae"
    if (( _fixed > 0 )); then
      spin_ok "$(_plural "$_fixed" binary) re-signed"
    elif (( _bad > 0 )); then
      spin_warn "$(_plural "$_bad" binary) could not be re-signed"
    else
      spin_skip "no tainted signatures ($_checked checked)"
    fi
    section_end
  fi

  # ── dotfiles ──────────────────────────────────────────────────────────────────
  section "Dotfiles"
  command -v stow &>/dev/null || abort "stow not found — run: brew install stow"
  cd "$DOTFILES"
  step "Stowing ${#PACKAGES[@]} packages"
  for pkg in "${PACKAGES[@]}"; do stow_pkg "$pkg"; done
  local _n_repl=${#STOW_REPLACED[@]}
  if (( ${#STOW_FAIL[@]} == 0 )); then
    if (( _n_repl > 0 )); then
      spin_ok "$(_plural "${#STOW_OK[@]}" package) stowed · $_n_repl replaced"
    else
      spin_ok "$(_plural "${#STOW_OK[@]}" package) stowed"
    fi
  else
    spin_fail "${#STOW_OK[@]}/${#PACKAGES[@]} stowed — failed: ${STOW_FAIL[*]}"
  fi
  if (( _n_repl > 0 )); then
    local _conflict
    while IFS= read -r _conflict; do
      [[ -n "$_conflict" ]] || continue
      item_rm "replaced ~/$_conflict"
    done <<<"$(printf '%s\n' "${STOW_REPLACED[@]}")"
  fi
  step "Pruning stale links"
  prune_links
  if (( ${#PRUNED[@]} > 0 )); then
    local _link
    while IFS= read -r _link; do
      [[ -n "$_link" ]] || continue
      item_rm "pruned ~/$_link"
    done <<<"$(printf '%s\n' "${PRUNED[@]}")"
    spin_ok "$(_plural "${#PRUNED[@]}" stale link) pruned"
  else
    spin_skip "no stale links"
  fi
  section_end

  # ── local env ─────────────────────────────────────────────────────────────────
  # Machine-local API keys and env vars live at ~/.config/zsh/env.local — outside
  # this repo and never stowed, so secrets can't land in the working tree. Create
  # it once from a template; later runs only enforce 600, so a stray chmod can
  # never leave it world-readable. uninstall never touches it.
  section "Local env"
  local _umask
  _umask=$(umask)
  ENV_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/env.local"
  if [[ ! -f "$ENV_FILE" ]]; then
    step "Creating env.local"
    mkdir -p "$(dirname "$ENV_FILE")"
    umask 077
    cat >"$ENV_FILE" <<'ENVEOF'
# ~/.config/zsh/env.local — machine-local secrets and env vars
# NOT tracked by git · chmod 600 · sourced by ~/.zshenv in every zsh shell.
# One per line:  export NAME=value
# Consumed from config via env-var substitution (e.g. {env:NAME} in opencode).
ENVEOF
    chmod 600 "$ENV_FILE"
    umask "$_umask"
    spin_ok "created ~/.config/zsh/env.local"
  else
    chmod 600 "$ENV_FILE"
    spin_skip "env.local (600)"
  fi

  # GitHub MCP token: OpenCode's background server does not inherit shell env when
  # it is relaunched from the desktop, and its config can only read env vars or
  # file contents — never a command — so the token lives in a 600 file refreshed
  # here from the gh keyring. A new machine needs one `gh auth login` and one more
  # sync; nothing to hand-edit. printf, not a plain redirection: a trailing
  # newline would corrupt the Authorization header.
  GH_TOKEN_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/github_token"
  if command -v gh >/dev/null 2>&1 && gh auth token >/dev/null 2>&1; then
    step "Refreshing GitHub token"
    umask 077
    printf '%s' "$(gh auth token)" >"$GH_TOKEN_FILE"
    chmod 600 "$GH_TOKEN_FILE"
    umask "$_umask"
    spin_ok "token refreshed"
  elif [[ -f "$GH_TOKEN_FILE" ]]; then
    chmod 600 "$GH_TOKEN_FILE"
    spin_skip "github_token (cached)"
  else
    spin_warn "github token missing — run 'gh auth login', then ./sync.sh"
  fi
  section_end

  # ── tmux plugins ──────────────────────────────────────────────────────────────
  section "tmux plugins"
  TPM_DIR="$HOME/.tmux/plugins/tpm"
  if [[ ! -d "$TPM_DIR" ]]; then
    step "Cloning TPM"
    git clone --quiet --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR" || abort "TPM clone failed"
    spin_ok "TPM cloned"
  else
    spin_skip "TPM present"
  fi
  step "Installing plugins"
  if "$TPM_DIR/bin/install_plugins" &>/dev/null; then
    spin_ok "plugins synced"
  else
    spin_warn "plugin install failed"
  fi
  section_end

  # ── shell ─────────────────────────────────────────────────────────────────────
  section "Shell"
  ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
  if [[ ! -d "$ZINIT_HOME" ]]; then
    step "Installing zinit"
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone --quiet https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" || abort "zinit clone failed"
    spin_ok "zinit installed"
  else
    spin_skip "zinit present"
  fi
  section_end

  # ── runtimes ──────────────────────────────────────────────────────────────────
  section "Runtimes"
  command -v mise &>/dev/null || abort "mise not found"
  local _rt_before="" _rt_after="" _rt_diff="" _rt_inv="" _mout _uout _rt_n=0 _rt_total=0
  step "Syncing runtimes"
  # not `command -v jq && …` — a failing AND-list is fatal under set -e
  if command -v jq &>/dev/null; then _rt_before="$(mise_snapshot)"; fi
  _mout=$(mise install --yes 2>&1) || abort "mise install failed: $_mout"
  _uout=$(mise upgrade --yes 2>&1) || abort "mise upgrade failed: $_uout"
  if [[ -n "$_rt_before" ]]; then
    _rt_after="$(mise_snapshot)"
    # a runtime present only afterwards was missing; one whose version moved was
    # upgraded. Env vars instead of temp files, and no associative arrays — bash
    # 3.2 on macOS has neither `declare -A` nor `mapfile`.
    _rt_diff=$(RT_BEFORE="$_rt_before" RT_AFTER="$_rt_after" perl -e '
        my (%old, %new);
        for my $line (split /\n/, ($ENV{RT_BEFORE} // "")) {
          my ($k, $v) = split /\t/, $line, 2;
          $old{$k} = $v if defined $v;
        }
        for my $line (split /\n/, ($ENV{RT_AFTER} // "")) {
          my ($k, $v) = split /\t/, $line, 2;
          $new{$k} = $v if defined $v;
        }
        for my $k (sort keys %new) {
          # `-` holds the old-version column on new rows: tab counts as IFS
          # whitespace, so an empty field would collapse and shift the columns
          if (!exists $old{$k})        { print "new\t$k\t-\t$new{$k}\n" }
          elsif ($old{$k} ne $new{$k}) { print "upd\t$k\t$old{$k}\t$new{$k}\n" }
        }
      ')
  fi
  local _rt_old _rt_new
  if [[ -n "$_rt_diff" ]]; then
    while IFS=$'\t' read -r kind name _rt_old _rt_new; do
      [[ -n "$name" ]] || continue
      # backend-qualified names shorten to the binary they provide
      # (go:golang.org/x/tools/cmd/gopls → gopls)
      case "$name" in *:*) name="${name##*:}"; name="${name##*/}" ;; esac
      _rt_n=$(( _rt_n + 1 ))
      if [[ "$kind" == "new" ]]; then
        item_new "$name $_rt_new"
      else
        item_upd "$name $_rt_old → $_rt_new"
      fi
    done <<<"$_rt_diff"
  fi
  # live inventory: buffered, counted, and only printed with -v — it is stable
  # data, so it should not pad every run's output
  eval "$(mise env)"
  _rt_inv="$(mise_snapshot)"
  if [[ -z "$_rt_inv" ]]; then
    _rt_inv="$(mise ls --current 2>/dev/null | awk 'NF >= 2 { print $1"\t"$2 }' || true)"
  fi
  while IFS=$'\t' read -r name version; do
    [[ -n "$name" ]] || continue
    case "$name" in *:*) name="${name##*:}"; name="${name##*/}" ;; esac
    _rt_total=$(( _rt_total + 1 ))
    _item_extra "$name $version"
  done <<<"$_rt_inv"
  if (( _rt_n > 0 )); then
    spin_ok "$(_plural "$_rt_n" runtime) changed"
  elif [[ -n "$_rt_before" ]]; then
    spin_skip "up to date ($_rt_total)"
  elif echo "$_mout" | grep -q "all tools are installed" \
    && echo "$_uout" | grep -qi "up to date"; then
    spin_skip "up to date ($_rt_total)"
  else
    # no jq — mise's wording says *that* something changed, never which runtime
    if ! echo "$_mout" | grep -q "all tools are installed"; then item_new "installed missing runtimes"; fi
    if ! echo "$_uout" | grep -qi "up to date"; then item_upd "upgraded outdated runtimes"; fi
    spin_ok "updated ($_rt_total)"
  fi
  section_end

  # ── editor ────────────────────────────────────────────────────────────────────
  section "Editor"
  if command -v nvim &>/dev/null; then
    local lock="$DOTFILES/nvim/.config/nvim/lazy-lock.json"
    local lock_before="" lock_dirty_before=false
    if [[ -f "$lock" ]]; then
      lock_before="$(mktemp)"
      cp "$lock" "$lock_before"
    fi
    git -C "$DOTFILES" diff --quiet -- nvim/.config/nvim/lazy-lock.json 2>/dev/null || lock_dirty_before=true
    local nvim_log _nvim_sync_ok=true
    step "Syncing plugins"
    nvim_log="$(nvim --headless "+Lazy! sync" +qa 2>&1)" || _nvim_sync_ok=false
    local _plugin_diff="" _n_plug=0 _nvim_tail=""
    if ! $_nvim_sync_ok; then
      spin_fail "plugin sync failed"
      _nvim_tail="$(printf '%s\n' "$nvim_log" | tail -n 5)"
    else
      if [[ -n "$lock_before" && -f "$lock" ]] && command -v jq &>/dev/null; then
        _plugin_diff=$(jq -sr '
            (.[0] // {}) as $old | (.[1] // {}) as $new |
            ($new | keys[]) as $k
            | ($old[$k].commit // "") as $o | ($new[$k].commit) as $n
            | select($o != $n)
            | "\(if $o == "" then "new" else "upd" end)\t\($k)\t\($o[0:7])\t\($n[0:7])"
          ' "$lock_before" "$lock" 2>/dev/null) || true
      fi
      local kind name old new
      while IFS=$'\t' read -r kind name old new; do
        [[ -z "$name" ]] && continue
        _n_plug=$(( _n_plug + 1 ))
        if [[ "$kind" == "new" ]]; then item_new "$name  $new"; else item_upd "$name  $old → $new"; fi
      done <<<"$_plugin_diff"
      if (( _n_plug > 0 )); then
        spin_ok "$(_plural "$_n_plug" plugin) changed"
      else
        spin_skip "plugins up to date"
      fi
      if [[ -n "$lock_before" ]] && ! $lock_dirty_before && ! git -C "$DOTFILES" diff --quiet -- nvim/.config/nvim/lazy-lock.json 2>/dev/null; then
        local _commit_resp="y"
        if $_TTY; then
          printf "    ${Y}?${NC} commit lockfile update? [Y/n] "
          read -r _commit_resp
        fi
        if [[ -z "$_commit_resp" || "$_commit_resp" =~ ^[Yy]$ ]]; then
          if git -C "$DOTFILES" add nvim/.config/nvim/lazy-lock.json 2>/dev/null \
            && git -C "$DOTFILES" commit -m "⬆️ nvim: update plugin lockfile" >/dev/null 2>&1; then
            item_new "committed lockfile update"
          else
            item_note "lockfile changed but auto-commit failed"
          fi
        else
          item_note "lockfile commit skipped"
        fi
      fi
    fi
    rm -f "$lock_before"
  else
    spin_warn "neovim not found — skipped"
  fi
  section_end
  # failure detail belongs *under* the section line, not above it
  if [[ -n "${_nvim_tail:-}" ]]; then
    while IFS= read -r _line; do
      [[ -n "$_line" ]] || continue
      printf "    ${D}%s${NC}\n" "$_line"
    done <<<"$_nvim_tail"
  fi

  finish
}

# ── entrypoint ──────────────────────────────────────────────────────────────────

case "$_CMD" in
  sync)      cmd_sync ;;
  bootstrap) cmd_bootstrap ;;
  uninstall) cmd_uninstall ;;
  *) usage >&2; exit 1 ;;
esac
