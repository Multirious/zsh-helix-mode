{
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "zsh-helix-mode";
  version = "git";

  src = ./.;

  strictDeps = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/share/zsh-helix-mode
    cp *.zsh $out/share/zsh-helix-mode/
  '';

  meta = with lib; {
    description = "Helix keybinding for Z Shell";
    homepage = "https://github.com/Multirious/zsh-helix-mode";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ ];
  };
}
