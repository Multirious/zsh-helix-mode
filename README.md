# zsh-helix-mode
A WIP Helix keybinding for Z Shell.

Bring comfort of working with Helix keybindings to your Zsh environment.

This plugin attempts to implement Helix keybindings as accurate and complete
as much as possible. Any keybinds that should reflect official default Helix keybinds, but doesn't, are considered bugs.

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

You can change the cursor color and shape for each mode via these environment variables:
- `ZHM_CURSOR_NORMAL`
- `ZHM_CURSOR_SELECT`
- `ZHM_CURSOR_INSERT`

The content of these variables should be a string of terminal escape sequences that modify the looks of your terminal cursor.
These are printed everytime after mode changes.

### Behavior

`ZHM_CLIPBOARD_PIPE_CONTENT_TO`

The content of this variable should be a command that you want the yanked content to be piped to.
If `DISPLAY` variable is found, the default will be `xclip -sel clip`.
If `WAYLAND_DISPLAY` variable is found, the default will be `wl-copy`.
Otherwise it is empty.

`ZHM_CLIPBOARD_READ_CONTENT_FROM`

The content of this variable should be a command that outputs clipboard
content to stdout. It is used in pasting operations.
If `DISPLAY` variable is found, the default will be `xclip -o -sel clip`.
If `WAYLAND_DISPLAY` variable is found, the default will be `wl-paste --no-newline`.
Otherwise it is empty.

#### Keymapping

### Compatibility