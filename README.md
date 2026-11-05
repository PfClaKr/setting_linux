# setting_linux

The files I put on every new Linux machine: a vimrc and a two-line prompt, for bash
(no oh-my-zsh needed) or zsh.

```text
╭─  ychun@laptop ~/setting_linux ‹main*›                     127 ↵  [21:04:13]
╰─➤
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/PfClaKr/setting_linux/main/install.sh | bash
```

or from a clone:

```bash
git clone https://github.com/PfClaKr/setting_linux && cd setting_linux
./install.sh            # vimrc + bash prompt + extras
./install.sh --zsh      # also the oh-my-zsh theme
```

| What | Where it goes |
|---|---|
| `vimrc` | `~/.vimrc` |
| `ychun.bash-theme`, `extras.bash` | `~/.config/setting_linux/`, sourced by a marked block at the end of `~/.bashrc` |
| `ychun.zsh-theme` (`--zsh`) | `$ZSH_CUSTOM/themes/`, and `ZSH_THEME="ychun"` in `~/.zshrc` |

Files that already exist and differ are kept as `<file>.bak.<timestamp>`. Running the script
again only refreshes the files; `~/.bashrc` never gets a second block. To undo, delete the
`# >>> setting_linux >>>` block from `~/.bashrc` and `~/.config/setting_linux/`, and restore
`~/.vimrc` from its backup.

## Files

- **`vimrc`**: loads Vim's `defaults.vim` (which a `~/.vimrc` otherwise disables), tabs shown 4
  wide with one tab per indent level, line numbers, highlighted search, smart case, mouse,
  and `utf-8,cp949` so Korean files saved on Windows open correctly.
- **`ychun.bash-theme`**: the prompt for bash. User in red as root, host in red over SSH, git
  branch with `*` when the tree is dirty, exit code and time on the right of the first line.
- **`extras.bash`**: history settings (big, deduplicated, timestamped), `EDITOR=vim`, and the
  aliases `c` and `sysupdate`.
- **`ychun.zsh-theme`**, **`.zshrc`**: the original zsh setup, based on oh-my-zsh's `bira` theme.

What each line does, and the checklist I go through on a fresh machine:
<https://pfclakr.github.io/ko/posts/etc/setting-linux/> (also in
[English](https://pfclakr.github.io/posts/etc/setting-linux/) and
[French](https://pfclakr.github.io/fr/posts/etc/setting-linux/)).
