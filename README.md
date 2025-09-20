# zsh-helix-mode
Bring comfort of working with Helix keybindings to your Zsh environment.

This plugin attempts to implement Helix keybindings as accurate and complete
as much as possible while respecting existing shell workflows.
Any existing keybindings that *should* reflect the official default Helix keybinds but doesn't are considered bugs.

**Features**
- Accurate Helix replication! No more switching muscle memory.
- Helix's selection manipulation and movement.
- Match, Goto, Insert, Append, Change, Delete, Replace.
- Multi-cursor, Registers, Shell Pipe, Command mode!
- Yank-Paste for both registers and clipboard!
- Undo-Redo! And with selection history like Helix's.
- Multi-line mode. It's Helix editor right in your prompt!
- Cursor styling. Display different modes with different cursor looks.

Post an issue or submit a PR if you need any missing feature! May it be a keybind widget or command (for command mode) or anything else.

---

#### Sections
- [Installation](#Installation)
  - [Manual](#manual)
  - [zplug](#zplug)
  - [Antigen](#antigen)
  - [Oh My Zsh](#oh-my-zsh)
  - [Nix (non-flake)](#nix-non-flake)
  - [Nix (flake)](#nix-flake)
- [Configurations](#configurations)
  - [Styling](#styling)
  - [Clipboard](#clipboard)
  - [Compatibility](#compatibility)
- [Plugin Specifics](#plugin-specifics)

## Installation

### Manual

Clone the repository to wherever you'd like and source the plugin.
```sh
git clone https://github.com/Multirious/zsh-helix-mode --depth 1
source ./zsh-helix-mode/zsh-helix-mode.plugin.zsh
```

### [zplug](https://github.com/zplug/zplug)

```sh
zplug "multirious/zsh-helix-mode", depth:1, at:main
```

### [Antigen](https://github.com/zsh-users/antigen)

```sh
antigen bundle multirious/zsh-helix-mode@main
```

### [Oh My Zsh](https://github.com/ohmyzsh)

clone the repository to `$ZSH_CUSTOM/plugins` folder:
```sh
git clone https://github.com/Multirious/zsh-helix-mode --depth 1 $ZSH_CUSTOM/plugins/zsh-helix-mode
```
And add the plugin to the `plugins` array:
```
plugins=(zsh-helix-mode)
```

### [Nix](https://nixos.org/) (non-flake)
```nix
let
  zsh-helix-mode = pkgs.fetchFromGithub {
    owner = "multirious";
    repo = "zsh-helix-mode";
    rev = "...";
    sha256 = "...";
  };
in
''
source ${zsh-helix-mode}/zsh-helix-mode.plugin.zsh
''
```

### [Nix](https://nixos.org/) ([flake](https://nix.dev/concepts/flakes.html))

Add the input to your flake:

```nix
{
  inputs = {
    zsh-helix-mode.url = "github:multirious/zsh-helix-mode/main";
    zsh-helix-mode.inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

#### Install using NixOS ZSH module

```nix
{
  programs.zsh = {
    interactiveShellInit = ''
      source ${pkgs.zsh-helix-mode}/share/zsh-helix-mode/zsh-helix-mode.plugin.zsh
    '';
  };
}
```

#### Install using Home-Manager module

```nix
{
  programs.zsh = {
    plugins = [
      {
        name = "zsh-helix-mode";
        src = pkgs.zsh-helix-mode;
        file = "share/zsh-helix-mode/zsh-helix-mode.plugin.zsh";
      }
    ];
  };
}
```

## Configurations

### Styling

You can change the cursor color and shape for each mode via these environment variables.
The content of these variables should be a string of terminal escape sequences that modify the looks of your terminal cursor.
These are printed everytime after mode changes.


`ZHM_CURSOR_NORMAL`
- Prints the variable whenever the mode changes to normal mode.
- By default, it is `\e[0m\e[2 q\e]12;#B4BEFE\a` which is a string of ANSI escape sequences<br/>
that basically means "reset, block cursor, pastel blue".

`ZHM_CURSOR_SELECT`
- Prints the variable whenever the mode changes to select mode.
- By default, it is `\e[0m\e[2 q\e]12;#F2CDCD\a` which is a string of ANSI escape sequences<br/>
that basically means "reset, block cursor, pastel red".

`ZHM_CURSOR_INSERT`
- Prints the variable whenever the mode changes to insert mode.
- By default, it is `\e[0m\e[5 q\e]12;white\a` which is a string of ANSI escape sequences<br/>
that basically means "reset, vertical blinking cursor, white".

These variables use the syntax from https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html#Character-Highlighting

`ZHM_STYLE_CURSOR_SELECT`, default is `fg=black,bg=#f2cdcd`

`ZHM_STYLE_CURSOR_INSERT`, default is `fg=black,bg=#a6e3a1`

`ZHM_STYLE_OTHER_CURSOR_NORMAL`, default is `fg=black,bg=#878ec0`

`ZHM_STYLE_OTHER_CURSOR_SELECT`, default is `fg=black,bg=#b5a6a8`

`ZHM_STYLE_OTHER_CURSOR_INSERT`, default is `fg=black,bg=#7ea87f`

`ZHM_STYLE_SELECTION`, default is `fg=white,bg=#45475a`

### Clipboard

`ZHM_CLIPBOARD_PIPE_CONTENT_TO`
- System yanked content will be piped to the command in this variable.
- By default, it is `xclip -sel clip` if the `DISPLAY` environment variable is found,<br/>
or `wl-copy` if the `WAYLAND_DISPLAY` environment variable is found,<br/>
otherwise it is empty.


`ZHM_CLIPBOARD_READ_CONTENT_FROM`
- System paste will use the stdout output from the command in this variable.
- By default, it is `xclip -o -sel clip` if the `DISPLAY` environment variable is found,<br/>
or `wl-paste --no-newline` if the `WAYLAND_DISPLAY` environment variable is found,<br/>
otherwise it is empty.

### Compatibility

#### [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions?tab=readme-ov-file#widget-mapping)
For `zsh-autosuggestions` to work with `zsh-helix-mode` you must configure `zsh-autosuggestions`
to use widgets implemented by this plugin:
```zsh
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(
  zhm_history_prev
  zhm_history_next
  zhm_prompt_accept
  zhm_accept
  zhm_accept_or_insert_newline
)
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS+=(
  zhm_move_right
  zhm_clear_selection_move_right
)
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(
  zhm_move_next_word_start
  zhm_move_next_word_end
)
```
More details [here](https://github.com/zsh-users/zsh-autosuggestions?tab=readme-ov-file#widget-mapping).

This still have some issues and that is partial accepting using `zhm_move_next_word_start` or `zhm_move_next_word_end`
will leave one last character unaccepted which some can considered them undesirable/annoying (I know I am).
Please submit an issue/PR if you have a solution!

#### [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
Due to how `zsh-syntax-highlighting` works,
[you must source the plugin after `zsh-helix-mode`](https://github.com/zsh-users/zsh-syntax-highlighting?tab=readme-ov-file#why-must-zsh-syntax-highlightingzsh-be-sourced-at-the-end-of-the-zshrc-file).

`zsh-syntax-highlighting` can override `zsh-helix-mode`'s highlighting. To
mitigate the issue, please add the following after you've sourced `zsh-syntax-highlighting`:
```zsh
# source zsh-helix-mode

# source zsh-syntax-highlighting

zhm-add-update-region-highlight-hook
```

#### [fzf](https://github.com/junegunn/fzf)
Please add the following after you've sourced zsh-helix-mode and fzf shell integration (in any order):
```zsh
zhm_wrap_widget fzf-completion zhm_fzf_completion
bindkey '^I' zhm_fzf_completion
```

#### [fzf-tab](https://github.com/Aloxaf/fzf-tab)
Please add the following after you've sourced zsh-helix-mode and fzf-tab (in any order):
```zsh
zhm_wrap_widget fzf-tab-complete zhm_fzf_tab_complete
bindkey '^I' zhm_fzf_tab_complete
```

# Plugin Specifics
This section document some features that is different to Helix.

Press `Alt-Enter` in any mode for toggling multi-line mode.
Press `Ctrl-p`/`Ctrl-n` in any mode for moving in the command history.

The register `%` will returns the output of the `pwd` command. Originally, it is "current file path" in Helix.

By pressing `Alt-Enter`, the editor will be switched to multi-line mode.
In this mode, a message `-- MULTILINE --` with a newline is prepended to your
commandline to ensure your first line in the buffer is at the same level
to any other lines. Pressing `Enter` key in insert mode will add a newline
at your cursor instead of accepting the command. However, pressing `Enter`
key in normal mode is the same; it will accepts the current command as usual.
Other keys will behave the same.
