# ~/.zprofile — Load khi login shell
# Dùng cho setup môi trường một lần khi đăng nhập

# Homebrew (Apple Silicon) — cần có ở đây cho các login shell
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
