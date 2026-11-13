#!/bin/sh
# Test harness for sync.sh — no framework, no network, no Homebrew, no Neovim.
#
# Every case runs as its own `sh` process in a fresh sandbox: a throwaway $HOME
# (so ~/.config and ~/.zshrc are never the real ones), a throwaway
# $XDG_DATA_HOME, and a PATH whose first entry holds the stubs this file writes
# — `nvim` included. Cases call the functions under test directly; `cmd_sync` is
# never run, so nothing touches brew, mise, stow or the real dotfiles.
#
#   ./tests/sync_test.sh            all cases
#   ./tests/sync_test.sh mason      only cases whose name contains "mason"
#
# Covered: probing a directory that does not exist yet (the fresh-machine crash),
# the mason provisioning step (fresh / incremental / up to date / nvim fails),
# the EXIT-trap wording (abort vs signal), link snapshots and pruning without a
# ~/.config, and flag parsing / colour-free non-TTY output. Not covered: anything
# needing real Homebrew, mise or Neovim (i.e. network and sudo).
set -uo pipefail

# SYNC can be overridden to point the suite at another copy of the script
# (handy for checking that a case actually fails when the bug is reintroduced).
SYNC="${SYNC:-$(cd "$(dirname "$0")/.." && pwd)/sync.sh}"
WORK="$(mktemp -d)"
BASE_PATH="$PATH"
FILTER="${1:-}"

cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

# ── sandbox ───────────────────────────────────────────────────────────────────

mkdir -p "$WORK/bin"
cat >"$WORK/bin/nvim" <<'STUB'
#!/bin/sh
# stub for `nvim --headless "+MasonToolsInstallSync" +qa`; STUB_NVIM picks what
# it pretends mason did to its bin dir. Ignores its arguments on purpose.
bin="${XDG_DATA_HOME}/nvim/mason/bin"
case "${STUB_NVIM:-nothing}" in
  install2) mkdir -p "$bin"; : >"$bin/lua-language-server"; : >"$bin/stylua" ;;
  install1) mkdir -p "$bin"; : >"$bin/vtsls" ;;
  fail)     echo "mason: registry unreachable" >&2; exit 1 ;;
  nothing)  : ;;
esac
exit 0
STUB
chmod +x "$WORK/bin/nvim"

cat >"$WORK/bin/sudo" <<'STUB'
#!/bin/sh
# stub for sudo; STUB_SUDO picks the auth state. Only `-n` (non-interactive
# probe) and `-v` (validate/authenticate) are ever called by preauth_sudo.
case "${STUB_SUDO:-cached}" in
  cached)   [[ "${1:-}" == "-n" ]] && exit 0; exit 0 ;;
  ask-ok)   [[ "${1:-}" == "-n" ]] && exit 1; exit 0 ;;
  ask-fail) exit 1 ;;
esac
STUB
chmod +x "$WORK/bin/sudo"

# ── assertions ────────────────────────────────────────────────────────────────

PASS=0
FAIL=0
FAILED=""
_CASE=""
_CASE_FAILS=0
_OUT=""
_RC=0

_begin() { _CASE="$1"; _CASE_FAILS=0; }

_end() {
  if (( _CASE_FAILS == 0 )); then
    PASS=$(( PASS + 1 ))
    printf '  ✓ %s\n' "$_CASE"
  else
    FAIL=$(( FAIL + 1 ))
    FAILED="$FAILED
  $_CASE"
    printf '  ✗ %s\n' "$_CASE"
  fi
}

_boom() {
  _CASE_FAILS=$(( _CASE_FAILS + 1 ))
  printf '      %s\n' "$*"
  # keep the failing output on screen, indented, so a red case is debuggable
  # without a re-run
  printf '%s\n' "$_OUT" | sed 's/^/        | /'
}

# run_case <body on stdin>: executes the body in a fresh sandbox, capturing
# output and exit status. `"$SYNC"` is exported so bodies can source it.
# Every case gets its own $HOME/$XDG_DATA_HOME — cases that write files (a
# dangling link, a file where mason's dir should be) must not leak into the next.
_CASE_SEQ=0
_SB=""
new_sandbox() {
  _CASE_SEQ=$(( _CASE_SEQ + 1 ))
  _SB="$WORK/sandbox.$_CASE_SEQ"
  mkdir -p "$_SB/home"
}

run_case() {
  local file="$WORK/case.sh"
  new_sandbox
  cat >"$file"
  _OUT="$(
    HOME="$_SB/home" XDG_DATA_HOME="$_SB/data" \
      PATH="$WORK/bin:$BASE_PATH" SYNC="$SYNC" \
      STUB_NVIM="${STUB_NVIM:-nothing}" STUB_SUDO="${STUB_SUDO:-cached}" \
      NO_COLOR=1 sh -u "$file" 2>&1
  )"
  _RC=$?
  STUB_NVIM=nothing
  STUB_SUDO=cached
}

rc_is() {
  [[ "$_RC" == "$1" ]] || _boom "exit code: expected $1, got $_RC"
}

out_has() {
  case "$_OUT" in
    *"$1"*) : ;;
    *) _boom "output missing: $1" ;;
  esac
}

out_lacks() {
  case "$_OUT" in
    *"$1"*) _boom "output should not contain: $1" ;;
    *) : ;;
  esac
}

out_empty() {
  [[ -z "$_OUT" ]] || _boom "expected no output"
}

# a must appear before b — used where order is the point (erase after prompt)
out_order() {
  local a="$1" b="$2" rest
  case "$_OUT" in
    *"$a"*) rest="${_OUT#*"$a"}" ;;
    *) _boom "output missing: $a"; return ;;
  esac
  case "$rest" in
    *"$b"*) : ;;
    *) _boom "expected '$a' before '$b'" ;;
  esac
}

# ── cases ─────────────────────────────────────────────────────────────────────

# The fresh-machine crash: mason's bin dir does not exist until its first
# package install, so counting it must read 0 instead of aborting the run.
t_count_missing_dir() {
  _begin "count: directory that does not exist yet reads 0"
  run_case <<'EOF'
. "$SYNC"
printf '%s\n' "$(_count_dir "$XDG_DATA_HOME/nvim/mason/bin")"
EOF
  rc_is 0
  out_has "0"
  _end
}

t_count_entries() {
  _begin "count: existing directory counts its entries"
  run_case <<'EOF'
. "$SYNC"
mkdir -p "$XDG_DATA_HOME/bin"
: >"$XDG_DATA_HOME/bin/a"
: >"$XDG_DATA_HOME/bin/b"
printf '%s\n' "$(_count_dir "$XDG_DATA_HOME/bin")"
EOF
  rc_is 0
  out_has "2"
  _end
}

t_count_file_path() {
  _begin "count: a file where a directory was expected reads 0"
  run_case <<'EOF'
. "$SYNC"
mkdir -p "$XDG_DATA_HOME"
: >"$XDG_DATA_HOME/nvim"
printf '%s\n' "$(_count_dir "$XDG_DATA_HOME/nvim/mason/bin")"
EOF
  rc_is 0
  out_has "0"
  _end
}

t_mason_fresh_machine() {
  _begin "mason: fresh machine installs and reports the count"
  STUB_NVIM=install2 run_case <<'EOF'
. "$SYNC"
section "Editor"
provision_language_servers
section_end
EOF
  rc_is 0
  out_has "➤ Editor"
  out_has "✓ 2 installed (2)"
  out_lacks "interrupted"
  _end
}

t_mason_incremental() {
  _begin "mason: one new server on an existing install"
  STUB_NVIM=install1 run_case <<'EOF'
. "$SYNC"
mkdir -p "$XDG_DATA_HOME/nvim/mason/bin"
: >"$XDG_DATA_HOME/nvim/mason/bin/a"
: >"$XDG_DATA_HOME/nvim/mason/bin/b"
section "Editor"
provision_language_servers
section_end
EOF
  rc_is 0
  out_has "✓ 1 installed (3)"
  _end
}

t_mason_up_to_date() {
  _begin "mason: nothing to install reports up to date"
  STUB_NVIM=nothing run_case <<'EOF'
. "$SYNC"
mkdir -p "$XDG_DATA_HOME/nvim/mason/bin"
: >"$XDG_DATA_HOME/nvim/mason/bin/a"
section "Editor"
provision_language_servers
section_end
EOF
  rc_is 0
  out_has "◎ up to date (1)"
  _end
}

# A failing nvim is a warning, not a dead run: the servers are optional for a
# sync to be considered successful.
t_mason_nvim_fails() {
  _begin "mason: nvim failure warns instead of aborting"
  STUB_NVIM=fail run_case <<'EOF'
. "$SYNC"
section "Editor"
provision_language_servers
section_end
EOF
  rc_is 0
  out_has "! language server install failed"
  out_has "mason: registry unreachable"
  out_lacks "interrupted"
  _end
}

# The bug that started this: a `set -e` abort mid-step used to be reported as
# "interrupted", blaming the user.
t_trap_abort_label() {
  _begin "trap: errexit abort reads 'failed (exit N)'"
  run_case <<'EOF'
. "$SYNC"
section "Editor"
step "Provisioning language servers"
false
EOF
  rc_is 1
  out_has "— failed (exit 1)"
  out_lacks "interrupted"
  _end
}

t_trap_signal_label() {
  _begin "trap: SIGINT reads 'interrupted'"
  run_case <<'EOF'
. "$SYNC"
section "Editor"
step "Provisioning language servers"
kill -INT $$
EOF
  rc_is 130
  out_has "— interrupted"
  _end
}

t_trap_completed_step() {
  _begin "trap: a closed step prints nothing extra"
  run_case <<'EOF'
. "$SYNC"
section "Editor"
step "Provisioning language servers"
spin_skip "up to date (3)"
section_end
EOF
  rc_is 0
  out_has "◎ up to date (3)"
  out_lacks "✗"
  _end
}

# ~/.config does not exist on a bare machine; both `find "$HOME/.config"` probes
# used to kill the run there.
t_snapshot_without_config() {
  _begin "stow snapshot: no ~/.config is not a failure"
  run_case <<'EOF'
. "$SYNC"
stow_snapshot
EOF
  rc_is 0
  out_empty
  _end
}

t_prune_without_config() {
  _begin "prune: no ~/.config is not a failure"
  run_case <<'EOF'
. "$SYNC"
prune_links
EOF
  rc_is 0
  out_empty
  _end
}

# Accuracy, not just survival: the snapshot exists to answer "did stowing change
# anything", so a link appearing must change it.
t_snapshot_detects_change() {
  _begin "stow snapshot: an added link changes the snapshot"
  run_case <<'EOF'
. "$SYNC"
mkdir -p "$HOME/.config"
before="$(stow_snapshot)"
ln -s "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"
after="$(stow_snapshot)"
[[ -z "$before" ]] && printf 'before-empty\n'
[[ -n "$after" ]] && printf 'after-nonempty\n'
EOF
  rc_is 0
  out_has "before-empty"
  out_has "after-nonempty"
  _end
}

# A dangling link back into this repo is exactly what a dropped package leaves
# behind; a live link to a listed package must survive.
t_prune_removes_dangling_only() {
  _begin "prune: drops dangling links, keeps live ones"
  run_case <<'EOF'
. "$SYNC"
mkdir -p "$HOME/.config"
# resolve a real tracked file instead of hardcoding a package name, so renaming
# packages doesn't turn this into a false failure
pkg="${PACKAGES[0]}"
kept="$(find "$DOTFILES/$pkg" -type f -print -quit)"
ln -s "$kept" "$HOME/.kept"
ln -s "$DOTFILES/gone-package/nothing-here" "$HOME/.gone"
prune_links
[[ -L "$HOME/.kept" ]] && printf 'kept-live\n'
[[ -e "$HOME/.gone" || -L "$HOME/.gone" ]] || printf 'dropped-dangling\n'
EOF
  rc_is 0
  out_has "kept-live"
  out_has "dropped-dangling"
  _end
}

# ── sudo pre-auth ─────────────────────────────────────────────────────────────

# Cached credentials (sudo's timestamp) mean the note and the prompt would both
# be noise — the common second-run case.
t_preauth_skips_when_cached() {
  _begin "sudo: cached credentials skip the prompt entirely"
  STUB_SUDO=cached run_case <<'EOF'
. "$SYNC"
_TTY=true
preauth_sudo "some-cask other-cask"
printf 'after\n'
EOF
  rc_is 0
  out_has "after"
  out_lacks "may ask for your password"
  out_lacks "$(printf '\033[2A')"
  _end
}

# After the password is entered the scaffolding must be wiped, because
# `step "Checking packages"` repeats the same words on the next row.
t_preauth_erases_prompt() {
  _begin "sudo: prompt lines are erased once the password is entered"
  STUB_SUDO=ask-ok run_case <<'EOF'
. "$SYNC"
_TTY=true
preauth_sudo "some-cask"
printf 'step-line\n'
EOF
  rc_is 0
  out_has "may ask for your password"
  out_has "$(printf '\033[2A\033[J')"
  out_order "$(printf '\033[2A\033[J')" "step-line" || true
  out_has "step-line"
  _end
}

# A wrong password or ^C has to remain readable — erasing it would hide sudo's
# own error.
t_preauth_keeps_failure() {
  _begin "sudo: a failed prompt stays on screen"
  STUB_SUDO=ask-fail run_case <<'EOF'
. "$SYNC"
_TTY=true
preauth_sudo "some-cask"
printf 'step-line\n'
EOF
  rc_is 0
  out_has "may ask for your password"
  out_lacks "$(printf '\033[2A')"
  out_has "step-line"
  _end
}

t_preauth_no_pending_casks() {
  _begin "sudo: no pending cask means no prompt"
  STUB_SUDO=ask-ok run_case <<'EOF'
. "$SYNC"
_TTY=true
preauth_sudo "   "
printf 'after\n'
EOF
  rc_is 0
  out_has "after"
  out_lacks "may ask for your password"
  out_lacks "$(printf '\033[2A')"
  _end
}

# Piped output (logs, CI) is never interactive and never gets escape codes.
t_preauth_non_tty() {
  _begin "sudo: non-TTY output is never prompted"
  STUB_SUDO=ask-ok run_case <<'EOF'
. "$SYNC"
preauth_sudo "some-cask"
printf 'after\n'
EOF
  rc_is 0
  out_has "after"
  out_lacks "may ask for your password"
  out_lacks "$(printf '\033')"
  _end
}

# ── flag parsing / output contract ────────────────────────────────────────────

t_flag_help() {
  _begin "flags: --help exits 0 with usage"
  _OUT="$(NO_COLOR=1 sh "$SYNC" --help 2>&1)"
  _RC=$?
  rc_is 0
  out_has "usage:"
  _end
}

t_flag_unknown() {
  _begin "flags: unknown flag exits 1 with usage"
  _OUT="$(NO_COLOR=1 sh "$SYNC" --nope 2>&1)"
  _RC=$?
  rc_is 1
  out_has "usage:"
  _end
}

# Piped output is what CI and logs see: no escape codes, no spinner frames.
t_non_tty_is_plain() {
  _begin "output: piped run carries no escape codes"
  new_sandbox
  _OUT="$(
    NO_COLOR=1 sh "$SYNC" --help 2>&1
    HOME="$_SB/home" XDG_DATA_HOME="$_SB/data" PATH="$WORK/bin:$BASE_PATH" \
      SYNC="$SYNC" NO_COLOR=1 sh -u -c '. "$SYNC"; section "Editor"; step "x"; spin_ok "done"; section_end' 2>&1
  )"
  _RC=$?
  rc_is 0
  out_lacks "$(printf '\033')"
  out_lacks "$(printf '\r')"
  _end
}

# Sourcing must load functions only — a library load that ran cmd_sync would
# rewrite the machine during a test.
t_library_mode() {
  _begin "library: sourcing sync.sh runs no command"
  run_case <<'EOF'
. "$SYNC"
printf 'sourced\n'
command -v provision_language_servers >/dev/null && printf 'has-functions\n'
EOF
  rc_is 0
  out_has "sourced"
  out_has "has-functions"
  out_lacks "➤"
  _end
}

# ── runner ────────────────────────────────────────────────────────────────────

CASES="
t_count_missing_dir
t_count_entries
t_count_file_path
t_mason_fresh_machine
t_mason_incremental
t_mason_up_to_date
t_mason_nvim_fails
t_trap_abort_label
t_trap_signal_label
t_trap_completed_step
t_snapshot_without_config
t_prune_without_config
t_snapshot_detects_change
t_prune_removes_dangling_only
t_preauth_skips_when_cached
t_preauth_erases_prompt
t_preauth_keeps_failure
t_preauth_no_pending_casks
t_preauth_non_tty
t_flag_help
t_flag_unknown
t_non_tty_is_plain
t_library_mode
"

printf '\nsync.sh tests\n'
for case_fn in $CASES; do
  if [[ -n "$FILTER" && "$case_fn" != *"$FILTER"* ]]; then continue; fi
  "$case_fn"
done

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
if (( FAIL > 0 )); then
  printf 'failed:%s\n\n' "$FAILED"
  exit 1
fi
printf '\n'
