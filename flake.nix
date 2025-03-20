{
  description = "My personal website used to learn and test things.";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";

    flake-compat.url = "github:edolstra/flake-compat";

    crane.url = "github:ipetkov/crane";

    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };

  outputs = { self, nixpkgs-stable, crane, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs-stable = import nixpkgs-stable {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        # Use the toolchain from the `rust-toolchain.toml` file
        rustToolchain =
          pkgs-stable.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        craneLib = (crane.mkLib pkgs-stable).overrideToolchain rustToolchain;

      in {
        # Development Environments
        devShells.default = craneLib.devShell {
          shell = pkgs-stable.nushell;

          # Extra inputs can be added here;
          # - cargo and rustc are provided by default from craneLib.
          packages = with pkgs-stable; [
            # IDE integrations
            nil
            nixfmt-classic
            rust-analyzer
            nodePackages.prettier

            # Dev Tools
            trunk
            nushell
            wrangler
            nodePackages.nodejs
          ];

          RUST_SRC_PATH = rustToolchain.passthru.availableComponents.rust-src;
        };
      });
}
