#!/usr/bin/env bash
# =============================================================================
# dotfiles/install.sh
# Interactive bootstrap script — setup a new Mac with checklist UI
# Usage: ./install.sh [--all] [--skip-brew] [--skip-node] [--skip-shell]
# =============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_PREFIX="[dotfiles]"

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'; CYAN='\033[0;36m'
DIM='\033[2m'

info()    { echo -e "${BLUE}${LOG_PREFIX}${RESET} $*"; }
success() { echo -e "${GREEN}${LOG_PREFIX} ✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}${LOG_PREFIX} ⚠${RESET} $*"; }
error()   { echo -e "${RED}${LOG_PREFIX} ✗${RESET} $*" >&2; }
header()  { echo -e "\n${BOLD}${BLUE}══ $* ══${RESET}"; }

# ── Flags ────────────────────────────────────────────────────────────────────
INSTALL_ALL=false
SKIP_BREW=false
SKIP_NODE=false
SKIP_SHELL=false

for arg in "$@"; do
  case $arg in
    --all)        INSTALL_ALL=true ;;
    --skip-brew)  SKIP_BREW=true   ;;
    --skip-node)  SKIP_NODE=true   ;;
    --skip-shell) SKIP_SHELL=true  ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --all           Install everything without interactive prompt"
      echo "  --skip-brew     Skip Homebrew installation"
      echo "  --skip-node     Skip Node.js installation"
      echo "  --skip-shell    Skip shell setup (zinit, Starship)"
      echo "  --help, -h      Show this help message"
      exit 0
      ;;
  esac
done

# ── Check macOS ──────────────────────────────────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
  error "This script only runs on macOS!"
  exit 1
fi

# ── Detection Functions ──────────────────────────────────────────────────────
check_homebrew() {
  command -v brew &>/dev/null && return 0 || return 1
}

check_mise() {
  command -v mise &>/dev/null && return 0 || return 1
}

check_starship() {
  command -v starship &>/dev/null && return 0 || return 1
}

check_zinit() {
  [[ -d "${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git" ]] && return 0 || return 1
}

check_node() {
  command -v node &>/dev/null && return 0 || return 1
}

check_pnpm() {
  command -v pnpm &>/dev/null && return 0 || return 1
}

check_bun() {
  command -v bun &>/dev/null && return 0 || return 1
}

check_symlinks() {
  [[ -L "$HOME/.zshrc" ]] && [[ "$(readlink "$HOME/.zshrc")" == *"dotfiles"* ]] && return 0 || return 1
}

check_font() {
  [[ -f "$HOME/Library/Fonts/MonofurNerdFont-Regular.ttf" ]] && return 0 || return 1
}

# ── Interactive Checklist ────────────────────────────────────────────────────
show_interactive_menu() {
  # Ensure TERM is set for terminal operations
  [[ -z "$TERM" ]] && export TERM=xterm-256color

  # Clear screen and show header once
  clear 2>/dev/null || printf "\n\n\n"

  printf "${CYAN}"
  cat << 'EOF'
    ____        __  _____ __
   / __ \____  / /_/ __(_) /__  _____
  / / / / __ \/ __/ /_/ / / _ \/ ___/
 / /_/ / /_/ / /_/ __/ / /  __(__  )
/_____/\____/\__/_/ /_/_/\___/____/

EOF
  printf "${RESET}"
  printf "${DIM}                    Interactive Setup Wizard${RESET}\n"
  printf "${DIM}                    Author: ${BOLD}onepercman${RESET}\n"
  printf "\n"
  printf "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════════╗${RESET}\n"
  printf "${BOLD}${CYAN}║${RESET}              ${BOLD}Select components to install${RESET}                          ${BOLD}${CYAN}║${RESET}\n"
  printf "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════════╝${RESET}\n"
  printf "\n"

  # Define all installation options (using arrays compatible with bash 3.2)
  local -a OPTIONS
  OPTIONS[0]="Homebrew & Essential Tools (mise, mole, starship)"
  OPTIONS[1]="Monofur Nerd Font"
  OPTIONS[2]="zinit (Plugin Manager) + Plugins"
  OPTIONS[3]="Starship Prompt"
  OPTIONS[4]="Node.js (via mise)"
  OPTIONS[5]="pnpm Package Manager"
  OPTIONS[6]="bun Runtime"
  OPTIONS[7]="Terminal.app Profile (Clear Dark with Monofur)"
  OPTIONS[8]="Create Symlinks (.zshrc, .gitconfig, etc.)"

  # Auto-detect what's already installed
  local -a SELECTED
  check_homebrew || SELECTED[0]=1
  check_font || SELECTED[1]=1
  check_zinit || SELECTED[2]=1
  check_starship || SELECTED[3]=1
  check_node || SELECTED[4]=1
  check_pnpm || SELECTED[5]=1
  check_bun || SELECTED[6]=1
  SELECTED[7]=1  # Always suggest terminal profile setup
  check_symlinks || SELECTED[8]=1

  local current=0
  local total=8

  # Function to draw menu
  draw_menu() {
    # Move cursor to menu start position (line 14) without clearing
    printf "\033[14;1H"

    # Draw menu items
    for i in $(seq 0 $total); do
      local checkbox="[ ]"
      local status=""

      # Check if already installed
      if check_item_installed $i; then
        status="${GREEN}✓${RESET}"
      else
        status="${YELLOW}⚠${RESET}"
      fi

      # Set checkbox state
      if [[ ${SELECTED[$i]:-0} -eq 1 ]]; then
        checkbox="[${GREEN}✓${RESET}]"
      fi

      # Clear line and draw item
      printf "\033[2K"
      # Highlight current item
      if [[ $i -eq $current ]]; then
        printf "${CYAN}▶${RESET} ${BOLD}${checkbox}${RESET} ${OPTIONS[$i]} ${status}\n"
      else
        printf "  ${checkbox} ${OPTIONS[$i]} ${status}\n"
      fi
    done

    # Clear remaining lines and draw footer
    printf "\033[2K\n"
    printf "\033[2K${DIM}────────────────────────────────────────────────────────────────────────${RESET}\n"
    printf "\033[2K${DIM}Use ${BOLD}↑↓${RESET}${DIM} to navigate, ${BOLD}SPACE${RESET}${DIM} to toggle, ${BOLD}ENTER${RESET}${DIM} to continue${RESET}\n"
  }

  check_item_installed() {
    case $1 in
      0) check_homebrew ;;
      1) check_font ;;
      2) check_zinit ;;
      3) check_starship ;;
      4) check_node ;;
      5) check_pnpm ;;
      6) check_bun ;;
      7) return 1 ;;  # Terminal profile - always show as not installed
      8) check_symlinks ;;
    esac
  }

  # Initial draw
  draw_menu

  # Handle keyboard input
  while true; do
    # Read single character
    IFS= read -rsn1 key

    # Handle arrow keys (escape sequences)
    if [[ $key == $'\x1b' ]]; then
      # Read next character to check for escape sequence
      read -rsn1 -t 1 key2
      if [[ $key2 == "[" ]]; then
        # Read the arrow key code
        read -rsn1 -t 1 key3
        case $key3 in
          A) # Up arrow
            ((current > 0)) && ((current--))
            draw_menu
            ;;
          B) # Down arrow
            ((current < total)) && ((current++))
            draw_menu
            ;;
        esac
      fi
    elif [[ $key == " " ]]; then
      # Space - toggle selection
      if [[ ${SELECTED[$current]:-0} -eq 1 ]]; then
        SELECTED[$current]=0
      else
        SELECTED[$current]=1
      fi
      draw_menu
    elif [[ $key == "" ]]; then
      # Enter - confirm
      break
    fi
  done

  echo ""

  # Export selections
  export INSTALL_BREW=${SELECTED[0]:-0}
  export INSTALL_FONT=${SELECTED[1]:-0}
  export INSTALL_ZINIT=${SELECTED[2]:-0}
  export INSTALL_STARSHIP=${SELECTED[3]:-0}
  export INSTALL_NODE=${SELECTED[4]:-0}
  export INSTALL_PNPM=${SELECTED[5]:-0}
  export INSTALL_BUN=${SELECTED[6]:-0}
  export INSTALL_TERMINAL=${SELECTED[7]:-0}
  export INSTALL_SYMLINKS=${SELECTED[8]:-0}
}

# ── Main Installation Flow ───────────────────────────────────────────────────
header "Starting dotfiles setup"
info "DOTFILES_DIR = $DOTFILES_DIR"

# Ensure ~/Developer directory exists
if [[ ! -d "$HOME/Developer" ]]; then
  info "Creating ~/Developer directory..."
  mkdir -p "$HOME/Developer"
  success "~/Developer directory created"
else
  success "~/Developer directory exists"
fi

# Show interactive menu unless --all flag is used
if [[ "$INSTALL_ALL" == true ]]; then
  INSTALL_BREW=1
  INSTALL_FONT=1
  INSTALL_ZINIT=1
  INSTALL_STARSHIP=1
  INSTALL_NODE=1
  INSTALL_PNPM=1
  INSTALL_BUN=1
  INSTALL_TERMINAL=1
  INSTALL_SYMLINKS=1
else
  show_interactive_menu
fi

# ── 1. Homebrew & packages ───────────────────────────────────────────────────
if [[ $INSTALL_BREW -eq 1 ]] && [[ "$SKIP_BREW" == false ]]; then
  header "Homebrew & Essential Tools"
  source "$DOTFILES_DIR/lib/brew.sh"
  install_homebrew
  install_packages "$DOTFILES_DIR/Brewfile"
fi

# ── 2. Font ──────────────────────────────────────────────────────────────────
if [[ $INSTALL_FONT -eq 1 ]] && [[ "$SKIP_BREW" == false ]]; then
  header "Monofur Nerd Font"
  # Source brew.sh if not already sourced
  [[ $(type -t install_font) != function ]] && source "$DOTFILES_DIR/lib/brew.sh"
  install_font
fi

# ── 3. zinit (Plugin Manager) ───────────────────────────────────────────────
if [[ "$SKIP_SHELL" == false ]]; then
  if [[ $INSTALL_ZINIT -eq 1 ]]; then
    header "zinit Plugin Manager"
    source "$DOTFILES_DIR/lib/zinit.sh"
    setup_shell
  fi
fi

# ── 4. Node.js via mise ──────────────────────────────────────────────────────
if [[ "$SKIP_NODE" == false ]]; then
  if [[ $INSTALL_NODE -eq 1 ]]; then
    header "Node.js"
    source "$DOTFILES_DIR/lib/node.sh"
    install_node
  fi

  if [[ $INSTALL_PNPM -eq 1 ]]; then
    install_pnpm
  fi

  if [[ $INSTALL_BUN -eq 1 ]]; then
    install_bun
  fi
fi

# ── 5. Terminal.app Profile ─────────────────────────────────────────────────
if [[ $INSTALL_TERMINAL -eq 1 ]]; then
  header "Terminal.app Profile"
  source "$DOTFILES_DIR/lib/terminal.sh"
  setup_terminal_profile
fi

# ── 6. Symlinks ──────────────────────────────────────────────────────────────
if [[ $INSTALL_SYMLINKS -eq 1 ]]; then
  header "Dotfiles Symlinks"
  source "$DOTFILES_DIR/lib/link.sh"
  create_symlinks "$DOTFILES_DIR"
fi

# ── Cleanup Recommendations ─────────────────────────────────────────────────
show_cleanup_recommendations() {
  local needs_cleanup=false
  local cleanup_items=()

  # Check for old nvm installation
  if [[ -d "$HOME/.nvm" ]] || brew list nvm &>/dev/null 2>&1; then
    needs_cleanup=true
    cleanup_items+=("nvm")
  fi

  # Check for Oh My Zsh
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    needs_cleanup=true
    cleanup_items+=("oh-my-zsh")
  fi

  # Check for Powerlevel10k
  if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]] || [[ -f "$HOME/.p10k.zsh" ]]; then
    needs_cleanup=true
    cleanup_items+=("powerlevel10k")
  fi

  # Check for old Node installations
  if brew list node &>/dev/null 2>&1; then
    needs_cleanup=true
    cleanup_items+=("node-brew")
  fi

  if [[ "$needs_cleanup" == true ]]; then
    echo ""
    echo -e "${YELLOW}${BOLD}╔═══════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${YELLOW}${BOLD}║${RESET}                  ${YELLOW}⚠${RESET}  ${BOLD}Cleanup Recommendations${RESET}                       ${YELLOW}${BOLD}║${RESET}"
    echo -e "${YELLOW}${BOLD}╚═══════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${DIM}You have old tools that can be removed now that you're using the new stack:${RESET}"
    echo ""

    for item in "${cleanup_items[@]}"; do
      case $item in
        nvm)
          echo -e "  ${YELLOW}•${RESET} ${BOLD}nvm${RESET} ${DIM}(replaced by mise)${RESET}"
          echo -e "    ${CYAN}# Remove nvm directory${RESET}"
          echo -e "    ${DIM}rm -rf ~/.nvm${RESET}"
          if brew list nvm &>/dev/null 2>&1; then
            echo -e "    ${CYAN}# Uninstall from Homebrew${RESET}"
            echo -e "    ${DIM}brew uninstall nvm${RESET}"
          fi
          echo -e "    ${CYAN}# Remove from shell config (if added manually)${RESET}"
          echo -e "    ${DIM}# Edit ~/.zshrc and remove nvm-related lines${RESET}"
          echo ""
          ;;
        oh-my-zsh)
          echo -e "  ${YELLOW}•${RESET} ${BOLD}Oh My Zsh${RESET} ${DIM}(replaced by zinit)${RESET}"
          echo -e "    ${CYAN}# Backup and remove Oh My Zsh${RESET}"
          echo -e "    ${DIM}mv ~/.oh-my-zsh ~/.oh-my-zsh.backup.\$(date +%Y%m%d)${RESET}"
          echo -e "    ${DIM}# zinit will manage plugins directly${RESET}"
          echo ""
          ;;
        powerlevel10k)
          echo -e "  ${YELLOW}•${RESET} ${BOLD}Powerlevel10k${RESET} ${DIM}(replaced by Starship)${RESET}"
          echo -e "    ${CYAN}# Remove theme${RESET}"
          echo -e "    ${DIM}rm -rf ~/.oh-my-zsh/custom/themes/powerlevel10k${RESET}"
          echo -e "    ${CYAN}# Remove config${RESET}"
          echo -e "    ${DIM}rm -f ~/.p10k.zsh${RESET}"
          echo ""
          ;;
        node-brew)
          echo -e "  ${YELLOW}•${RESET} ${BOLD}Node.js (Homebrew)${RESET} ${DIM}(now managed by mise)${RESET}"
          echo -e "    ${CYAN}# Uninstall from Homebrew${RESET}"
          echo -e "    ${DIM}brew uninstall node${RESET}"
          echo -e "    ${DIM}# mise will manage Node.js versions instead${RESET}"
          echo ""
          ;;
      esac
    done

    echo -e "${DIM}────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "${YELLOW}${BOLD}Note:${RESET} These are ${BOLD}optional${RESET} cleanups. Your system will work fine with or without them."
    echo ""
  fi
}

# ── Done ─────────────────────────────────────────────────────────────────────
# Ensure TERM is set for clear command
[[ -z "$TERM" ]] && export TERM=xterm-256color
clear 2>/dev/null || echo -e "\n\n\n"
echo -e "${GREEN}"
cat << 'EOF'
    ____        __  _____ __
   / __ \____  / /_/ __(_) /__  _____
  / / / / __ \/ __/ /_/ / / _ \/ ___/
 / /_/ / /_/ / /_/ __/ / /  __(__  )
/_____/\____/\__/_/ /_/_/\___/____/

EOF
echo -e "${RESET}"
echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║${RESET}                ${GREEN}✓${RESET} ${BOLD}Installation Complete!${RESET} ${GREEN}🎉${RESET}                        ${GREEN}${BOLD}║${RESET}"
echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${DIM}                    Author: ${BOLD}onepercman${RESET}"
echo ""

# Show cleanup recommendations if needed
show_cleanup_recommendations

echo -e "  ${GREEN}${BOLD}Next steps:${RESET}"
echo ""
echo "  1. ${BOLD}Restart your terminal${RESET} or run:"
echo "     ${CYAN}source ~/.zshrc${RESET}"
echo ""

# Show terminal profile note if it was installed
if [[ $INSTALL_TERMINAL -eq 1 ]]; then
  echo "  2. ${BOLD}Terminal profile applied!${RESET}"
  echo "     ${GREEN}✓${RESET} Profile: Clear Dark"
  echo "     ${GREEN}✓${RESET} Font: Monofur Nerd Font (14pt)"
  echo "     Open a new terminal window to see changes"
  echo ""
  echo "  3. ${BOLD}Customize Starship prompt${RESET}:"
else
  echo "  2. ${BOLD}Set terminal font${RESET} to:"
  echo "     ${CYAN}Monofur Nerd Font${RESET}"
  echo "     • Terminal.app: Preferences → Profiles → Font"
  echo "     • iTerm2: Preferences → Profiles → Text → Font"
  echo ""
  echo "  3. ${BOLD}Customize Starship prompt${RESET}:"
fi
echo "     ${CYAN}edit ~/.config/starship/starship.toml${RESET}"
echo ""
echo "  4. ${BOLD}Update git config${RESET} with your info:"
echo "     ${CYAN}git config --global user.name \"Your Name\"${RESET}"
echo "     ${CYAN}git config --global user.email \"your@email.com\"${RESET}"
echo ""
echo "  5. ${BOLD}Verify installation${RESET}:"
echo "     ${CYAN}mise doctor${RESET}"
echo "     ${CYAN}node --version${RESET}"
echo "     ${CYAN}pnpm --version${RESET}"
echo ""
echo -e "${DIM}Happy coding! ✨${RESET}"
echo ""
