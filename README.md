# zsh-helix-mode
A WIP Helix keybinding for Z Shell.

Bring comfort of working with Helix keybindings to your Zsh environment.

This plugin attempts to implement Helix keybindings as accurate and complete
as much as possible. The ideal is no more switching muscle memory!

## Installation

**No plugin manager**

Clone the repository to wherever you'd like and source the plugin.
```sh
git clone https://github.com/Multirious/zsh-helix-mode --depth 1
source ./zsh-helix-mode/zsh-helix-mode.plugin.zsh
```

**[Zplug](https://github.com/zplug/zplug)**

Following zplug's plugin installation, adds the below to your configuration:
```sh
zplug "multirious/zsh-helix-mode", depth:1, at:main
```

**[Antigen](https://github.com/zsh-users/antigen)**

Following antigen's plugin installation, adds the below to your configuration:
```sh
antigen bundle multirious/zsh-helix-mode@main
```

**[ohmyzsh](https://github.com/ohmyzsh)**

Clone the repository to `$ZSH_CUSTOM` folder
```sh
git clone https://github.com/Multirious/zsh-helix-mode --depth 1 $ZSH_CUSTOM/plugins/zsh-helix-mode
```
and following ohmyzsh's plugin installation, adds the plugin to the `plugin` array:
```
plugin=(zsh-helix-mode)
```

**[Nix](https://nixos.org/) (non-flake)**
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

**[Nix](https://nixos.org/) ([flake](https://nix.dev/concepts/flakes.html))**
```nix
{
  inputs = {
    zsh-helix-mode.url = "github:multirious/zsh-helix-mode/main"
  };
}
```
