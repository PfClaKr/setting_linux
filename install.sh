#!/usr/bin/env bash
# install.sh -- apply the vimrc and the ychun prompt in one go.
#
#   ./install.sh               from a clone: vimrc + bash prompt + extras + ble.sh
#   ./install.sh --vimzip      also install vimzip (~/vimzip, ~/.local/bin/vim)
#   ./install.sh --zsh         also install the oh-my-zsh theme
#   ./install.sh --no-blesh    without ble.sh (autosuggestions, syntax highlighting)
#   curl -fsSL https://raw.githubusercontent.com/PfClaKr/setting_linux/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/PfClaKr/setting_linux/main/install.sh | bash -s -- --vimzip
#
# Existing files are backed up as <file>.bak.<timestamp> before being replaced.
# Running it again is safe: it updates ~/.bashrc's one block instead of adding another.
set -euo pipefail

RAW=${SETTING_LINUX_RAW:-https://raw.githubusercontent.com/PfClaKr/setting_linux/main}
DEST=${XDG_CONFIG_HOME:-$HOME/.config}/setting_linux
STAMP=$(date +%Y%m%d-%H%M%S)
FILES=(vimrc ychun.bash-theme extras.bash blesh.bash ychun.zsh-theme)
BLESH_URL=${BLESH_URL:-https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz}
VIMZIP_URL=${VIMZIP_URL:-https://github.com/PfClaKr/vimzip/releases/latest/download/vimzip-linux-x86_64.tar.gz}

do_vim=1 do_bash=1 do_blesh=1 do_vimzip=0 do_zsh=0
usage() {
  sed -n '2,13s/^# \{0,1\}//p' "${BASH_SOURCE[0]:-/dev/null}" 2>/dev/null ||
    echo "usage: install.sh [--vimzip] [--zsh] [--no-blesh] [--no-vim] [--no-bash]"
  exit "${1:-0}"
}
for arg in "$@"; do
  case "$arg" in
    --zsh) do_zsh=1 ;;
    --vimzip) do_vimzip=1 ;;
    --no-blesh) do_blesh=0 ;;
    --no-vim) do_vim=0 ;;
    --no-bash) do_bash=0 do_blesh=0 ;;
    -h|--help) usage 0 ;;
    *) echo "unknown option: $arg" >&2; usage 1 ;;
  esac
done

say() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }

# download URL FILE
download() {
  if command -v curl >/dev/null; then
    curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null; then
    wget -qO "$2" "$1"
  else
    warn "need curl or wget"; return 1
  fi
}

TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT

# Where are the files? Next to this script in a clone, otherwise download them.
SRC=
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  [ -f "$SRC/vimrc" ] || SRC=
fi
if [ -z "$SRC" ]; then
  SRC=$TMP/src
  mkdir -p "$SRC"
  say "downloading from $RAW"
  for f in "${FILES[@]}"; do
    download "$RAW/$f" "$SRC/$f" || exit 1
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

# install_tarball URL DIR: unpack the archive's one top directory as DIR, replacing it
# only once the new copy is complete.
install_tarball() {
  local url=$1 dir=$2 tmp
  tmp=$(mktemp -d "$TMP/unpack.XXXXXX")
  download "$url" "$tmp/archive" || return 1
  mkdir "$tmp/x"
  tar --no-same-owner -xf "$tmp/archive" -C "$tmp/x" || return 1
  set -- "$tmp"/x/*/
  [ $# = 1 ] && [ -d "$1" ] || { warn "unexpected contents in $url"; return 1; }
  mkdir -p "$(dirname "$dir")"
  rm -rf -- "$dir.old"
  if [ -e "$dir" ]; then mv -- "$dir" "$dir.old"; fi
  mv -- "${1%/}" "$dir"
  rm -rf -- "$dir.old"
}

# ble.sh: the bash line editor that gives the gray suggestions and the coloring.
if [ "$do_blesh" = 1 ]; then
  blesh=${XDG_DATA_HOME:-$HOME/.local/share}/blesh
  if ! command -v xz >/dev/null; then
    warn "ble.sh needs xz to unpack (sudo apt install xz-utils); skipped"
  elif say "installing ble.sh into $blesh" && install_tarball "$BLESH_URL" "$blesh"; then
    say "installed ble.sh $(sed -n 's/^ *_ble_init_version=//p' "$blesh/ble.sh" | head -n 1)"
  else
    warn "could not install ble.sh; the prompt works without it"
  fi
fi

if [ "$do_bash" = 1 ]; then
  install_file "$SRC/ychun.bash-theme" "$DEST/ychun.bash-theme"
  install_file "$SRC/extras.bash" "$DEST/extras.bash"
  install_file "$SRC/blesh.bash" "$DEST/blesh.bash"
  rc=$HOME/.bashrc
  block=$(cat <<'EOF'
# >>> setting_linux >>>
for f in "${XDG_CONFIG_HOME:-$HOME/.config}"/setting_linux/{extras.bash,ychun.bash-theme,blesh.bash}; do
  [ -f "$f" ] && . "$f"
done
unset f
# <<< setting_linux <<<
EOF
)
  touch "$rc"
  old=$(sed -n '/^# >>> setting_linux >>>$/,/^# <<< setting_linux <<<$/p' "$rc")
  if [ "$old" = "$block" ]; then
    say "$rc already sources setting_linux"
  elif [ -n "$old" ]; then
    # Replace the block from an earlier version where it is, keeping the rest of the file.
    cp -p "$rc" "$rc.bak.$STAMP"
    printf '%s\n' "$block" > "$TMP/block"
    awk -v blockfile="$TMP/block" '
      /^# >>> setting_linux >>>$/ { while ((getline l < blockfile) > 0) print l; skip = 1; next }
      skip && /^# <<< setting_linux <<<$/ { skip = 0; next }
      !skip' "$rc.bak.$STAMP" > "$rc"
    say "updated the setting_linux block in $rc (backup: $rc.bak.$STAMP)"
  else
    cp -p "$rc" "$rc.bak.$STAMP"
    printf '\n%s\n' "$block" >> "$rc"
    say "added a setting_linux block to $rc (backup: $rc.bak.$STAMP)"
  fi
fi

# vimzip: a VSCode-like vim in one static archive. Its vim reads its own vimrc and
# ~/.config/vimzip/vimrc, not ~/.vimrc, which stays for the system's vim.
if [ "$do_vimzip" = 1 ]; then
  if [ "$(uname -s)-$(uname -m)" != Linux-x86_64 ]; then
    warn "vimzip is built for x86-64 Linux only; skipped"
  elif say "installing vimzip into ~/vimzip" && install_tarball "$VIMZIP_URL" "$HOME/vimzip"; then
    # vimzip's install.sh links ~/.local/bin/vim and adds PATH and EDITOR to the rc file
    # of $SHELL; run it once for each shell set up here.
    if [ "$do_zsh" = 1 ]; then SHELL=zsh sh "$HOME/vimzip/install.sh" >/dev/null; fi
    SHELL=bash sh "$HOME/vimzip/install.sh" >/dev/null
    say "installed vimzip; run: vim ."
  else
    warn "could not install vimzip"
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
