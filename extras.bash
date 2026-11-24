# extras.bash -- small bash settings that used to live in .zshrc.
# Sourced from ~/.bashrc by install.sh, after the distribution's defaults.

case $- in *i*) ;; *) return ;; esac

# History: keep a lot, skip duplicates and lines starting with a space,
# append instead of overwriting, and record when each command ran.
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T  '
shopt -s histappend cmdhist

export EDITOR=vim VISUAL=vim

alias c='clear'
alias sysupdate='sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoclean && sudo apt-get autoremove -y'
alias ll='ls -alF'
alias grep='grep --color=auto'

# ble.sh: the prompt already shows a failing exit code, so drop ble's "[ble: exit N]".
# The colors copy zsh-syntax-highlighting's defaults and zsh-autosuggestions' gray,
# with no background colors anywhere; selections are drawn reversed, as in zsh.
# Colors are numbers (3, not yellow): ble.sh reads names as the bright variants.
if [[ ${BLE_VERSION-} ]]; then
  bleopt exec_errexit_mark=
  # Commands green, keywords yellow, unknown commands red and bold, directories underlined.
  ble-face \
    command_file=fg=2 command_builtin=fg=2 command_builtin_dot=fg=2 \
    command_alias=fg=2 command_function=fg=2 command_jobs=fg=2 \
    command_keyword=fg=3 command_directory=fg=2,underline \
    command_suffix=fg=2,underline command_suffix_new=fg=1,bold \
    cmdinfo_cd_cdpath=fg=2,underline \
    syntax_error=fg=1,bold argument_error=fg=1 argument_option=none
  # Quotes and | ; > yellow, $var (the whole name) and escapes cyan, globs blue, comments gray.
  # (zsh leaves | and ; plain, but ble.sh colors them together with >.)
  ble-face \
    syntax_default=none syntax_command=none syntax_delimiter=fg=3 \
    syntax_quotation=fg=3 syntax_quoted=fg=3 syntax_escape=fg=6 \
    syntax_param_expansion=fg=6 syntax_varname=fg=6 syntax_expr=none \
    syntax_glob=fg=4 syntax_history_expansion=fg=4 syntax_brace=none \
    syntax_tilde=none syntax_comment=fg=8 syntax_function_name=fg=2 \
    syntax_document=none syntax_document_begin=none \
    varname_array=fg=6 varname_empty=fg=6 varname_export=fg=6 varname_expr=fg=6 \
    varname_hash=fg=6 varname_new=fg=6 varname_number=fg=6 varname_readonly=fg=6 \
    varname_transform=fg=6 varname_unset=fg=6
  # Paths that exist are underlined, nothing more.
  ble-face \
    filename_directory=underline filename_directory_sticky=underline \
    filename_executable=underline filename_link=underline filename_other=underline \
    filename_ls_colors=underline filename_url=underline filename_warning=underline \
    filename_block=underline filename_character=underline filename_pipe=underline \
    filename_socket=underline filename_setuid=underline filename_setgid=underline \
    filename_orphan=underline
  # Autosuggestion gray; the rest only replaces background colors.
  ble-face \
    auto_complete=fg=8 region=reverse region_match=reverse region_target=reverse \
    region_insert=underline overwrite_mode=reverse menu_filter_input=bold \
    prompt_status_line=reverse vbell_erase=none
fi
