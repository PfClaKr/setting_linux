#!/usr/bin/env bash
# install.sh -- set up a new machine: shell prompt, vimrc and vimzip in one go.
#
#   ./install.sh                 asks which shell to set up, bash or zsh
#   ./install.sh --shell bash    ychun prompt, extras, ble.sh (highlighting, autosuggestions)
#   ./install.sh --shell zsh     zsh, oh-my-zsh, ychun theme, zsh-autosuggestions, zsh-syntax-highlighting
#   curl -fsSL https://raw.githubusercontent.com/PfClaKr/setting_linux/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/PfClaKr/setting_linux/main/install.sh | bash -s -- --shell zsh
#
#   --no-blesh   bash without ble.sh          --no-vim     skip ~/.vimrc
#   --no-chsh    keep the current login shell --no-vimzip  skip vimzip
#
# Existing files are backed up as <file>.bak.<timestamp> before being replaced.
# Running it again is safe: the marked blocks in ~/.bashrc and ~/.zshrc are rewritten, not added twice.
set -euo pipefail

RAW=${SETTING_LINUX_RAW:-https://raw.githubusercontent.com/PfClaKr/setting_linux/main}
BLESH_URL=${BLESH_URL:-https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz}
VIMZIP_URL=${VIMZIP_URL:-https://github.com/PfClaKr/vimzip/releases/latest/download/vimzip-linux-$(uname -m).tar.gz}
DEST=${XDG_CONFIG_HOME:-$HOME/.config}/setting_linux
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
STAMP=$(date +%Y%m%d-%H%M%S)
FILES=(vimrc ychun.bash-theme extras.bash ychun.zsh-theme extras.zsh)

shell='' do_vim=1 do_vimzip=1 do_blesh=1 do_chsh=1
usage() {
  sed -n '2,14s/^# \{0,1\}//p' "${BASH_SOURCE[0]:-/dev/null}" 2>/dev/null ||
    echo "usage: install.sh [--shell bash|zsh] [--no-blesh] [--no-vim] [--no-vimzip] [--no-chsh]"
  exit "${1:-0}"
}
while [ $# -gt 0 ]; do
  case "$1" in
    --shell) shell=${2:-}; shift ;;
    --shell=*) shell=${1#*=} ;;
    --bash|--zsh) shell=${1#--} ;;
    --no-blesh) do_blesh=0 ;;
    --no-vim) do_vim=0 ;;
    --no-vimzip) do_vimzip=0 ;;
    --no-chsh) do_chsh=0 ;;
    -h|--help) usage 0 ;;
    *) echo "unknown option: $1" >&2; usage 1 ;;
  esac
  shift
done
case "$shell" in ''|bash|zsh) ;; *) echo "--shell must be bash or zsh" >&2; usage 1 ;; esac

say() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==>\033[0m %s\n' "$*" >&2; }
# A terminal to ask on, even when the script itself comes from `curl | bash`.
have_tty() { { : </dev/tty; } 2>/dev/null; }

if [ -z "$shell" ]; then
  if have_tty; then
    printf '\nWhich shell do you want to set up?\n' >/dev/tty
    printf '  1) bash  ychun prompt + ble.sh (syntax highlighting, autosuggestions)\n' >/dev/tty
    printf '  2) zsh   oh-my-zsh + ychun theme + zsh-autosuggestions, zsh-syntax-highlighting\n' >/dev/tty
    while :; do
      printf 'Choice [1]: ' >/dev/tty
      read -r reply </dev/tty || reply=
      case "$reply" in
        ''|1|bash) shell=bash; break ;;
        2|zsh) shell=zsh; break ;;
      esac
    done
  else
    shell=bash
    warn "no terminal to ask on: setting up bash (pass --shell zsh for zsh)"
  fi
fi
say "setting up $shell"

WORK=$(mktemp -d)
trap 'rm -rf -- "$WORK"' EXIT

# fetch URL FILE
fetch() {
  if command -v curl >/dev/null; then
    curl -fsSL "$1" -o "$2"
  elif command -v wget >/dev/null; then
    wget -qO "$2" "$1"
  else
    warn "need curl or wget"; return 1
  fi
}

# Run a command as root: directly when we are root, otherwise through sudo.
as_root() {
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then "$@"
  elif command -v sudo >/dev/null; then sudo "$@"
  else return 1
  fi
}

# Where are the files? Next to this script in a clone, otherwise download them.
SRC=
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SRC=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
  [ -f "$SRC/vimrc" ] || SRC=
fi
if [ -z "$SRC" ]; then
  SRC=$WORK/src
  mkdir -p "$SRC"
  say "downloading from $RAW"
  for f in "${FILES[@]}"; do
    fetch "$RAW/$f" "$SRC/$f"
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

# commit_rc NEW RC: replace RC with NEW when they differ, keeping a backup.
commit_rc() {
  local new=$1 rc=$2
  if [ -e "$rc" ] && cmp -s "$new" "$rc"; then
    say "$rc is already up to date"
    return
  fi
  if [ -s "$rc" ]; then
    cp -p "$rc" "$rc.bak.$STAMP"
    say "updated $rc (backup: $rc.bak.$STAMP)"
  else
    say "wrote $rc"
  fi
  cat "$new" >"$rc"
}

# set_block FILE NAME top|bottom [TEXT]: put TEXT between "# >>> NAME >>>" and
# "# <<< NAME <<<" at the top or the bottom of FILE, dropping the old block
# first. Without TEXT the block is only removed.
set_block() {
  local file=$1 name=$2 where=$3 text=${4:-} rest=$WORK/rest out=$WORK/out
  local begin="# >>> $name >>>" end="# <<< $name <<<"
  [ -e "$file" ] || : >"$file"
  awk -v b="$begin" -v e="$end" '$0 == b { skip = 1; next } $0 == e { skip = 0; next } !skip' \
    "$file" >"$rest"
  if [ -z "$text" ]; then
    cp "$rest" "$out"
  elif [ "$where" = top ]; then
    printf '%s\n%s\n%s\n' "$begin" "$text" "$end" | cat - "$rest" >"$out"
  else
    cp "$rest" "$out"
    # One blank line before the block, without piling them up on every run.
    [ -s "$out" ] && [ -n "$(tail -n 1 "$out")" ] && echo >>"$out"
    printf '%s\n%s\n%s\n' "$begin" "$text" "$end" >>"$out"
  fi
  cp "$out" "$file"
}

setup_bash() {
  install_file "$SRC/ychun.bash-theme" "$DEST/ychun.bash-theme"
  install_file "$SRC/extras.bash" "$DEST/extras.bash"

  if [ "$do_blesh" = 1 ]; then
    if [ -f "$DATA/blesh/ble.sh" ]; then
      say "ble.sh is already in $DATA/blesh (update it with: ble-update)"
    elif ! command -v xz >/dev/null; then
      warn "need xz to unpack ble.sh (sudo apt install xz-utils); skipped ble.sh"
    else
      say "installing ble.sh into $DATA/blesh"
      if ! { fetch "$BLESH_URL" "$WORK/ble.tar.xz" &&
             tar -xJf "$WORK/ble.tar.xz" -C "$WORK" &&
             bash "$WORK"/ble-*/ble.sh --install "$DATA" >/dev/null 2>&1; }; then
        warn "ble.sh did not install; the prompt works without it"
      fi
    fi
  fi
}

# The rc files are written last, after vimzip has added its own block, so that
# ours (and ble-attach in it) stays at the very end.
# shellcheck disable=SC2016  # the blocks are written out literally
rc_bash() {
  local rc=$HOME/.bashrc new=$WORK/bashrc
  if [ -e "$rc" ]; then cp "$rc" "$new"; else : >"$new"; fi
  # ble.sh wants to be loaded first and attached last.
  if [ "$do_blesh" = 1 ]; then
    set_block "$new" "setting_linux ble.sh" top \
'# ble.sh: syntax highlighting and autosuggestions (attached at the end of this file)
[[ $- == *i* && -f ${XDG_DATA_HOME:-$HOME/.local/share}/blesh/ble.sh ]] &&
  source -- "${XDG_DATA_HOME:-$HOME/.local/share}/blesh/ble.sh" --noattach'
  else
    set_block "$new" "setting_linux ble.sh" top
  fi
  set_block "$new" setting_linux bottom \
'for f in "${XDG_CONFIG_HOME:-$HOME/.config}"/setting_linux/{extras.bash,ychun.bash-theme}; do
  [ -f "$f" ] && . "$f"
done
unset f
[[ ! ${BLE_VERSION-} ]] || ble-attach'
  commit_rc "$new" "$rc"
}

setup_zsh() {
  if ! command -v zsh >/dev/null; then
    say "installing zsh"
    if ! command -v apt-get >/dev/null || ! as_root apt-get install -y zsh; then
      warn "could not install zsh: install it yourself and run this again"
      return 1
    fi
  fi
  command -v git >/dev/null || { warn "need git for oh-my-zsh and its plugins"; return 1; }

  local omz=${ZSH:-$HOME/.oh-my-zsh}
  if [ ! -d "$omz" ]; then
    say "installing oh-my-zsh into $omz"
    fetch https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh "$WORK/omz.sh"
    # Keeps an existing ~/.zshrc as ~/.zshrc.pre-oh-my-zsh and writes its template.
    ZSH=$omz RUNZSH=no CHSH=no sh "$WORK/omz.sh" --unattended
  fi
  local custom=${ZSH_CUSTOM:-$omz/custom} p
  for p in zsh-autosuggestions zsh-syntax-highlighting; do
    if [ ! -d "$custom/plugins/$p" ]; then
      say "installing $p"
      git clone -q --depth 1 "https://github.com/zsh-users/$p" "$custom/plugins/$p"
    fi
  done
  install_file "$SRC/ychun.zsh-theme" "$custom/themes/ychun.zsh-theme"
  install_file "$SRC/extras.zsh" "$DEST/extras.zsh"
}

# shellcheck disable=SC2016
rc_zsh() {
  local rc=$HOME/.zshrc new=$WORK/zshrc p
  if [ -e "$rc" ]; then cp "$rc" "$new"; else : >"$new"; fi
  if grep -q '^ZSH_THEME=' "$new"; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="ychun"/' "$new"
  else
    warn "no ZSH_THEME= line in $rc: add ZSH_THEME=\"ychun\" yourself"
  fi
  # Add the plugins to the last one-line plugins=(...), the one that counts.
  local n
  n=$(grep -n '^plugins=([^)]*)' "$new" | tail -n 1 | cut -d: -f1)
  if [ -n "$n" ]; then
    for p in zsh-autosuggestions zsh-syntax-highlighting; do
      sed -n "${n}p" "$new" | grep -Eq "[( ]${p}[ )]" ||
        sed -i -E "${n}s/^(plugins=\([^)]*)\)/\1 $p)/" "$new"
    done
  else
    warn "no one-line plugins=(...) in $rc: add zsh-autosuggestions zsh-syntax-highlighting yourself"
  fi
  set_block "$new" setting_linux bottom \
'[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/setting_linux/extras.zsh" ] &&
  . "${XDG_CONFIG_HOME:-$HOME/.config}/setting_linux/extras.zsh"'
  commit_rc "$new" "$rc"
}

install_vimzip() {
  local dir=$HOME/vimzip tmp
  say "downloading vimzip"
  if ! fetch "$VIMZIP_URL" "$WORK/vimzip.tar.gz"; then
    warn "no vimzip build at $VIMZIP_URL; skipped vimzip"
    return 0
  fi
  # Unpack next to ~/vimzip, then swap, so a failed download never leaves it half replaced.
  tmp=$(mktemp -d "$HOME/.vimzip.XXXXXX")
  if tar -xzf "$WORK/vimzip.tar.gz" -C "$tmp" && [ -x "$tmp/vimzip/install.sh" ]; then
    rm -rf -- "$dir"
    mv "$tmp/vimzip" "$dir"
    rm -rf -- "$tmp"
    SHELL=$shell "$dir/install.sh"
  else
    rm -rf -- "$tmp"
    warn "the vimzip archive did not unpack as expected; left $dir as it was"
  fi
}

# Make the chosen shell the login shell. Plain chsh refuses when the current
# shell is missing from /etc/shells (say, zsh was removed), so go through root.
set_login_shell() {
  local want cur
  want=$(command -v "$shell") || return 0
  cur=$(getent passwd "$USER" 2>/dev/null | cut -d: -f7) || cur=
  [ "$cur" = "$want" ] && { say "login shell is already $want"; return; }
  if ! have_tty; then
    warn "to make $shell your login shell, run: sudo chsh -s $want $USER"
    return
  fi
  say "changing the login shell of $USER: ${cur:-?} -> $want"
  if as_root chsh -s "$want" "$USER"; then
    say "login shell is now $want (log out and back in to use it everywhere)"
  else
    warn "could not change it; run: sudo chsh -s $want $USER"
  fi
}

: "${USER:=$(id -un)}"

if [ "$do_vim" = 1 ]; then
  install_file "$SRC/vimrc" "$HOME/.vimrc"
fi

"setup_$shell"

if [ "$do_vimzip" = 1 ]; then
  install_vimzip
elif [ "$do_vim" = 1 ] && ! command -v vim >/dev/null; then
  warn "vim is not installed (sudo apt install vim, or run without --no-vimzip)"
fi

"rc_$shell"

[ "$do_chsh" = 1 ] && set_login_shell

say "done. Open a new terminal (or run: exec $shell) to see it."
