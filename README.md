# setting_linux

The files I put on every new Linux machine: a vimrc and a two-line prompt, for bash
(no oh-my-zsh needed) or zsh. In bash, [ble.sh](https://github.com/akinomyoga/ble.sh) does
what zsh-autosuggestions and zsh-syntax-highlighting do in zsh, and
[vimzip](https://github.com/PfClaKr/vimzip) can come along too.

```text
╭─  ychun@laptop ~/setting_linux ‹main*›                     127 ↵  [21:04:13]
╰─➤
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/PfClaKr/setting_linux/main/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/PfClaKr/setting_linux/main/install.sh | bash -s -- --vimzip  # with vimzip
```

or from a clone:

```bash
git clone https://github.com/PfClaKr/setting_linux && cd setting_linux
./install.sh            # vimrc + bash prompt + extras + ble.sh
./install.sh --vimzip   # also vimzip
./install.sh --zsh      # also the oh-my-zsh theme
./install.sh --no-blesh # without ble.sh
```

| What | Where it goes |
|---|---|
| `vimrc` | `~/.vimrc` |
| `ychun.bash-theme`, `extras.bash`, `blesh.bash` | `~/.config/setting_linux/`, sourced by a marked block at the end of `~/.bashrc` |
| ble.sh (nightly release) | `~/.local/share/blesh/` |
| vimzip (`--vimzip`, latest release) | `~/vimzip/`, linked as `~/.local/bin/vim`; `PATH` and `EDITOR` in `~/.bashrc` (and `~/.zshrc` with `--zsh`) |
| `ychun.zsh-theme` (`--zsh`) | `$ZSH_CUSTOM/themes/`, and `ZSH_THEME="ychun"` in `~/.zshrc` |

Files that already exist and differ are kept as `<file>.bak.<timestamp>`. Running the script
again refreshes the files and updates ble.sh and vimzip; `~/.bashrc` never gets a second block
(a block from an older version is replaced). To undo, delete the `# >>> setting_linux >>>`
block from `~/.bashrc`, `~/.config/setting_linux/` and `~/.local/share/blesh/`, and restore
`~/.vimrc` from its backup. vimzip is removed as its README says.

## Files

- **`vimrc`**: loads Vim's `defaults.vim` (which a `~/.vimrc` otherwise disables), tabs shown 4
  wide with one tab per indent level, line numbers, highlighted search, smart case, mouse,
  and `utf-8,cp949` so Korean files saved on Windows open correctly.
- **`ychun.bash-theme`**: the prompt for bash. User in red as root, host in red over SSH, git
  branch with `*` when the tree is dirty, exit code and time on the right of the first line.
- **`extras.bash`**: history settings (big, deduplicated, timestamped), `EDITOR=vim`, and the
  aliases `c` and `sysupdate`.
- **`blesh.bash`**: loads ble.sh, colored like zsh-syntax-highlighting (commands green,
  unknown commands red, strings yellow) with gray suggestions from history like
  zsh-autosuggestions: `→`, `End` or `Ctrl+f` takes the suggestion, `Alt+f` one word of it.
  Does nothing when ble.sh is not installed.
- **`ychun.zsh-theme`**, **`.zshrc`**: the same prompt for zsh (needs oh-my-zsh; based on its `bira` theme).
- **vimzip** (`--vimzip`): a VSCode-like vim in one static archive, for x86-64 Linux. Its vim
  reads `~/.config/vimzip/vimrc`, not `~/.vimrc`, which stays for the system's `vim`.

What each line does, and the checklist I go through on a fresh machine:
<https://pfclakr.github.io/ko/posts/etc/setting-linux/> (also in
[English](https://pfclakr.github.io/posts/etc/setting-linux/) and
[French](https://pfclakr.github.io/fr/posts/etc/setting-linux/)).
