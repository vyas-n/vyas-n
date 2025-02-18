let
  nixpkgs = fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/tarball/nixpkgs-unstable";
    sha256 = "sha256:0wv8d61mvmi334k45qlpilwr4s9h5x33yrgihl1hz9p7s3mnfbzi";
  };
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
