#!/usr/bin/env bash
# install.sh -- apply the vimrc and the ychun prompt in one go.
#
#   ./install.sh               from a clone: vimrc + bash prompt + extras
#   ./install.sh --zsh         also install the oh-my-zsh theme
#   curl -fsSL https://raw.githubusercontent.com/PfClaKr/setting_linux/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/PfClaKr/setting_linux/main/install.sh | bash -s -- --zsh
#
# Existing files are backed up as <file>.bak.<timestamp> before being replaced.
# Running it again is safe: ~/.bashrc only ever gets one block.
set -euo pipefail

RAW=${SETTING_LINUX_RAW:-https://raw.githubusercontent.com/PfClaKr/setting_linux/main}
DEST=${XDG_CONFIG_HOME:-$HOME/.config}/setting_linux
STAMP=$(date +%Y%m%d-%H%M%S)
FILES=(vimrc ychun.bash-theme extras.bash ychun.zsh-theme)

do_vim=1 do_bash=1 do_zsh=0
usage() {
  sed -n '2,10s/^# \{0,1\}//p' "${BASH_SOURCE[0]:-/dev/null}" 2>/dev/null ||
    echo "usage: install.sh [--zsh] [--no-vim] [--no-bash]"
  exit "${1:-0}"
}
for arg in "$@"; do
  case "$arg" in
    --zsh) do_zsh=1 ;;
    --no-vim) do_vim=0 ;;
    --no-bash) do_bash=0 ;;
    -h|--help) usage 0 ;;
    *) echo "unknown option: $arg" >&2; usage 1 ;;
  esac
done

say() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }

# Where are the files? Next to this script in a clone, otherwise download them.
SRC=
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  [ -f "$SRC/vimrc" ] || SRC=
fi
if [ -z "$SRC" ]; then
  SRC=$(mktemp -d)
  trap 'rm -rf -- "$SRC"' EXIT
  say "downloading from $RAW"
  for f in "${FILES[@]}"; do
    if command -v curl >/dev/null; then
      curl -fsSL "$RAW/$f" -o "$SRC/$f"
    elif command -v wget >/dev/null; then
      wget -qO "$SRC/$f" "$RAW/$f"
    else
      warn "need curl or wget"; exit 1
    fi
  done
fi

# install_file SRC DEST: copy, keeping a backup of a different existing file.
install_file() {
  local from=$1 to=$2
  mkdir -p "$(dirname "$to")"
  if [ -e "$to" ] && ! cmp -s "$from" "$to"; then
    cp -p "$to" "$to.bak.$STAMP"
    say "backed up $to -> $to.bak.$STAMP"
  fi
  cp "$from" "$to"
  say "installed $to"
}

if [ "$do_vim" = 1 ]; then
  install_file "$SRC/vimrc" "$HOME/.vimrc"
  command -v vim >/dev/null || warn "vim is not installed (sudo apt install vim)"
fi

if [ "$do_bash" = 1 ]; then
  install_file "$SRC/ychun.bash-theme" "$DEST/ychun.bash-theme"
  install_file "$SRC/extras.bash" "$DEST/extras.bash"
  rc=$HOME/.bashrc
  touch "$rc"
  if grep -q '^# >>> setting_linux >>>' "$rc"; then
    say "$rc already sources setting_linux"
  else
    cp -p "$rc" "$rc.bak.$STAMP"
    cat >> "$rc" <<'EOF'

# >>> setting_linux >>>
for f in "${XDG_CONFIG_HOME:-$HOME/.config}"/setting_linux/{extras.bash,ychun.bash-theme}; do
  [ -f "$f" ] && . "$f"
done
unset f
# <<< setting_linux <<<
EOF
    say "added a setting_linux block to $rc (backup: $rc.bak.$STAMP)"
  fi
fi

if [ "$do_zsh" = 1 ]; then
  omz=${ZSH:-$HOME/.oh-my-zsh}
  if [ -d "$omz" ]; then
    install_file "$SRC/ychun.zsh-theme" "${ZSH_CUSTOM:-$omz/custom}/themes/ychun.zsh-theme"
    if [ -f "$HOME/.zshrc" ] && grep -q '^ZSH_THEME=' "$HOME/.zshrc"; then
      cp -p "$HOME/.zshrc" "$HOME/.zshrc.bak.$STAMP"
      sed -i 's/^ZSH_THEME=.*/ZSH_THEME="ychun"/' "$HOME/.zshrc"
      say "set ZSH_THEME=\"ychun\" in ~/.zshrc"
    else
      warn "add ZSH_THEME=\"ychun\" to ~/.zshrc yourself"
    fi
  else
    warn "oh-my-zsh not found in $omz; skipped the zsh theme"
  fi
fi

say "done. Open a new shell (or run: exec bash) to see the prompt."
