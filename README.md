# setting_linux

The files I put on every new Linux machine: a vimrc, [vimzip](https://github.com/PfClaKr/vimzip),
and a two-line prompt with syntax highlighting and autosuggestions, for bash or zsh.

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
./install.sh
```

It asks which shell to set up, then sets up that one and makes it your login shell
(`sudo chsh`, so it asks for your password). Pass `--shell bash` or `--shell zsh` to skip the
question; without a terminal to ask on, it sets up bash.

| Shell | What it installs |
|---|---|
| bash | `ychun.bash-theme` and `extras.bash` in `~/.config/setting_linux/`, and [ble.sh](https://github.com/akinomyoga/ble.sh) in `~/.local/share/blesh/` for syntax highlighting and autosuggestions (accept one with `→` or `Ctrl-F`). Marked blocks at the top and end of `~/.bashrc` load them. |
| zsh | zsh (apt), oh-my-zsh, `ychun.zsh-theme`, and the zsh-autosuggestions and zsh-syntax-highlighting plugins. `~/.zshrc` gets `ZSH_THEME="ychun"`, the two plugins, and a marked block that loads `extras.zsh`. |
| both | `vimrc` as `~/.vimrc`, and the latest vimzip release in `~/vimzip` (its own `install.sh` puts it on `PATH`). |

Options: `--no-blesh`, `--no-vim`, `--no-vimzip`, `--no-chsh` (keep the current login shell).

Files that already exist and differ are kept as `<file>.bak.<timestamp>`. Running the script
again refreshes the files and rewrites the marked blocks in place, so they are never added twice;
`~/vimzip` is replaced by the latest release. To undo, delete the `# >>> setting_linux` blocks
from `~/.bashrc` or `~/.zshrc` and `~/.config/setting_linux/`, and restore `~/.vimrc` from its backup.

## Files

- **`vimrc`**: loads Vim's `defaults.vim` (which a `~/.vimrc` otherwise disables), tabs shown 4
  wide with one tab per indent level, line numbers, highlighted search, smart case, mouse,
  and `utf-8,cp949` so Korean files saved on Windows open correctly. vimzip's vim uses its own
  vimrc; this one is for the system vim (`sudo vim`, other users).
- **`ychun.bash-theme`**: the prompt for bash. User in red as root, host in red over SSH, git
  branch with `*` when the tree is dirty, exit code and time on the right of the first line.
- **`extras.bash`**: history settings (big, deduplicated, timestamped), `EDITOR=vim`, and the
  aliases `c` and `sysupdate`.
- **`ychun.zsh-theme`**: the same prompt for zsh (needs oh-my-zsh; based on its `bira` theme).
- **`extras.zsh`**: `EDITOR=vim` and the aliases `c` and `sysupdate`; oh-my-zsh covers the rest.
- **`.zshrc`**: my old `~/.zshrc`, for reference; `install.sh` does not copy it.

What each line does, and the checklist I go through on a fresh machine:
<https://pfclakr.github.io/ko/posts/etc/setting-linux/> (also in
[English](https://pfclakr.github.io/posts/etc/setting-linux/) and
[French](https://pfclakr.github.io/fr/posts/etc/setting-linux/)).
