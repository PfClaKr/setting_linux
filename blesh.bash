# blesh.bash -- zsh-autosuggestions and zsh-syntax-highlighting for bash, through ble.sh
# (https://github.com/akinomyoga/ble.sh). install.sh puts ble.sh in ~/.local/share/blesh
# and sources this file from ~/.bashrc after the prompt. Without ble.sh it does nothing.
#
#   → / End / Ctrl+f    take the gray suggestion      Alt+f   take one word of it
#   Enter               run what is typed, without the suggestion

case $- in *i*) ;; *) return ;; esac
[ -n "${BLE_VERSION-}" ] && return    # already loaded (e.g. ~/.bashrc sourced twice)

__blesh=${XDG_DATA_HOME:-$HOME/.local/share}/blesh/ble.sh
if [ ! -f "$__blesh" ]; then unset __blesh; return; fi
# ble.sh takes over the line editor at the first prompt, after the rest of ~/.bashrc.
# shellcheck disable=SC1090
. "$__blesh"
unset __blesh
[ -n "${BLE_VERSION-}" ] || return    # bash too old, or not a terminal

# The prompt already shows the exit code; don't add "[ble: exit N]" lines too.
bleopt exec_errexit_mark=
# Look of zsh-autosuggestions: plain gray text, no background box.
ble-face -s auto_complete fg=244
# Colors of zsh-syntax-highlighting: commands green, keywords yellow, unknown red.
ble-face -s command_builtin fg=green
ble-face -s command_alias fg=green
ble-face -s command_function fg=green
ble-face -s command_file fg=green
ble-face -s command_keyword fg=yellow
ble-face -s syntax_quoted fg=yellow
ble-face -s syntax_quotation fg=yellow,bold
