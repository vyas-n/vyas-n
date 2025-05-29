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

  outputs =
    { self
    , nixpkgs-stable
    , crane
    , flake-utils
    , rust-overlay
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
          overlays = [ (import rust-overlay) ];
        };

        # Use the toolchain from the `rust-toolchain.toml` file
        rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;
      in
      {
        # Run Targets
        apps.default = {
          type = "app";
          program = "${pkgs.trunk}/bin/trunk";
        };

        # Build targets
        packages.default = pkgs.stdenv.mkDerivation {
          # Package info
          pname = "vyas-n-site";
          version = "0.1.0";

          # Build Tooling
          buildInputs = with pkgs; [ trunk cargo rustc nodePackages.nodejs cacert lld wasm-bindgen-cli ];

          # Environment Variables
          RUST_SRC_PATH = rustToolchain.passthru.availableComponents.rust-src;
          CARGO_HOME = "./.cargo-home";
          HOME = "./.home";

          # Build instructions
          src = ./.;
          buildPhase = ''
            mkdir -p $CARGO_HOME $HOME
            npm install
            trunk build --verbose --release
          '';
          installPhase = ''
            mkdir -p $out
            cp ./dist/* $out/
          '';
        };

        # Development Environments
        devShells.default = craneLib.devShell {
          # Extra inputs can be added here;
          # - cargo and rustc are provided by default from craneLib.
          packages =
            with pkgs;
            [
              # IDE integrations
              nil
              nixfmt-rfc-style
              nodePackages.prettier
              haskellPackages.hadolint

              # Dev Tools
              trunk
              nushell
              fish
              wrangler
              nodePackages.nodejs
            ]
            ++ [
              rustToolchain.passthru.availableComponents.rust-analyzer
            ];

          # Environment Variables
          RUST_SRC_PATH = rustToolchain.passthru.availableComponents.rust-src;
        };
      }
    );
}
