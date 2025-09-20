{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
  };

  outputs =
    { self, nixpkgs }:
    {
      packages =
        nixpkgs.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
          ]
          (system: rec {
            zsh-helix-mode = nixpkgs.legacyPackages.${system}.callPackage ./default.nix { };
            default = zsh-helix-mode;
          });

      overlays = {
        default = (
          final: prev: {
            zsh-helix-mode = self.packages.${prev.system}.zsh-helix-mode;
          }
        );

      };
    };

}
