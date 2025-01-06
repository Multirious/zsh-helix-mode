# zsh-helix-mode
A WIP Helix keybinding for Z Shell.

Bring comfort of working with Helix keybindings to your Zsh environment.

This plugin attempts to implement Helix keybindings as accurate and complete
as much as possible.
Any existing keybindings that *should* reflect the official default Helix keybinds but doesn't are considered bugs.

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
  - [Behavior](#behavior)
  - [Compatibility](#compatibility)

---

## Installation

### Manual

Clone the repository to wherever you'd like and source the plugin.
```sh
git clone https://github.com/Multirious/zsh-helix-mode --depth 1
source ./zsh-helix-mode/zsh-helix-mode.plugin.zsh
```

### [zplug](https://github.com/zplug/zplug)

Following zplug's plugin installation, add the below to your configuration:
```sh
zplug "multirious/zsh-helix-mode", depth:1, at:main
```

### [Antigen](https://github.com/zsh-users/antigen)

Following Antigen's plugin installation, add the below to your configuration:
```sh
antigen bundle multirious/zsh-helix-mode@main
```

### [Oh My Zsh](https://github.com/ohmyzsh)

Following Oh My Zsh's plugin installation, clone the repository to `$ZSH_CUSTOM/plugins` folder:
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
```nix
{
  inputs = {
    zsh-helix-mode.url = "github:multirious/zsh-helix-mode/main"
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

This plugin is currently an extension to ZLE. It uses ZLE's marking/highlighting feature to implement
selection which ZLE also provided some variables for stylign.

todo

### Behavior

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

#### Keymapping

todo

### Compatibility

If you wanted to use `zsh-autosuggestions` with this plugin, you can add the following configurations below:
```zsh
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(
  zhm_history_prev
  zhm_history_next
)
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS+=(
  zhm_move_right
)
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(
  zhm_move_next_word_start
  zhm_move_next_word_end
)
```
More details can be seen [here](https://github.com/zsh-users/zsh-autosuggestions?tab=readme-ov-file#widget-mapping).
This configuration has one caveat and that is partial accepting using `zhm_move_next_word_start` or `zhm_move_next_word_end`
will leave one last character unaccepted which some can considered them undesirable/annoying (I know I am).
Please submit an issue/PR if you have a solution!
