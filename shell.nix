let
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-24.05";
  pkgs = import nixpkgs {
    config = { };
    overlays = [ ];
  };

in pkgs.mkShellNoCC {
  packages = with pkgs; [ cowsay lolcat nushell nixfmt-classic npins ];
  shell = pkgs.nushell;

  GREETING = "Hello, Nix!";

  shellHook = ''
    echo $GREETING | cowsay | lolcat
  '';
}
