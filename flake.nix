{
  description = "Build a cargo project";

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";

    flake-compat.url = "github:edolstra/flake-compat";

    crane.url = "github:ipetkov/crane";

    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };

  outputs = { self, nixpkgs-unstable, nixpkgs-stable, crane, flake-utils
    , rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs-unstable = import nixpkgs-unstable { inherit system; };

        pkgs-stable = import nixpkgs-stable {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        inherit (pkgs-stable) lib;

        # Use the toolchain from the `rust-toolchain.toml` file
        rustToolchain =
          pkgs-stable.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        craneLib = (crane.mkLib pkgs-stable).overrideToolchain rustToolchain;

        # When filtering sources, we want to allow assets other than .rs files
        unfilteredRoot = ./.; # The original, unfiltered source
        src = lib.fileset.toSource {
          root = unfilteredRoot;
          fileset = lib.fileset.unions [
            # Default files from crane (Rust and cargo files)
            (craneLib.fileset.commonCargoSources unfilteredRoot)
            (lib.fileset.fileFilter
              (file: lib.any file.hasExt [ "html" "scss" ]) unfilteredRoot)
            # Example of a folder for images, icons, etc
            (lib.fileset.maybeMissing ./assets)
          ];
        };

        # Common arguments can be set here to avoid repeating them later
        commonArgs = {
          inherit src;
          strictDeps = true;
          # We must force the target for wasm builds, otherwise cargo will attempt to use your native target
          CARGO_BUILD_TARGET = "wasm32-unknown-unknown";

          buildInputs = [
            # Add additional build inputs here
          ] ++ lib.optionals pkgs-stable.stdenv.isDarwin [
            # Additional darwin specific inputs can be set here
            pkgs-stable.libiconv
          ];
        };

        # Build *just* the cargo dependencies, so we can reuse
        # all of that work (e.g. via cachix) when running in CI
        cargoArtifacts = craneLib.buildDepsOnly (commonArgs // {
          # You cannot run cargo test on a wasm build
          doCheck = false;
        });

        # Build the actual crate itself, reusing the dependency
        # artifacts from above.
        # This derivation is a directory you can put on a webserver.
        personal-site = craneLib.buildTrunkPackage (commonArgs // {
          inherit cargoArtifacts;
          # The version of wasm-bindgen-cli here must match the one from Cargo.lock.
          # When updating to a new version replace the hash values with lib.fakeHash,
          # then try to do a build, which will fail but will print out the correct value
          # for `hash`. Replace the value and then repeat the process but this time the
          # printed value will be for the second `hash` below
          wasm-bindgen-cli = pkgs-unstable.buildWasmBindgenCli rec {
            src = pkgs-unstable.fetchCrate {
              pname = "wasm-bindgen-cli";
              version = "0.2.93";
              hash = "sha256-DDdu5mM3gneraM85pAepBXWn3TMofarVR4NbjMdz3r0=";
              # hash = lib.fakeHash;
            };

            cargoDeps = pkgs-stable.rustPlatform.fetchCargoVendor {
              inherit src;
              inherit (src) pname version;
              hash = "sha256-s8srI+lu+DgQ+5BbaEXC4Ja/BL+K22LIl5Gd1PwNZZk=";
              # hash = lib.fakeHash;
            };
          };
        });

        fs = lib.fileset;

        node-modules = pkgs-stable.buildNpmPackage {
          pname = "personal-site";
          version = "0.1.0";
          src = fs.toSource {
            root = ./.;
            fileset = ./package.json;
          };
          dontNpmBuild = true;
          npmDeps = pkgs-stable.importNpmLock { npmRoot = ./.; };

          npmConfigHook = pkgs-stable.importNpmLock.npmConfigHook;
        };

        # bulma = nixpkgs-stable.stdenv.mkDerivation {
        #   name = "bulma";
        #   src = node-modules;
        #   installPhase = ''
        #     cp ${node-modules}/lib/node_modules/personal-site/node_modules/bulma/* $out/
        #   '';
        # };

      in {
        # Tests
        checks = {
          # Build the crate as part of `nix flake check` for convenience
          inherit personal-site;

          # Run clippy (and deny all warnings) on the crate source,
          # again, reusing the dependency artifacts from above.
          #
          # Note that this is done as a separate derivation so that
          # we can block the CI if there are issues here, but not
          # prevent downstream consumers from building our crate by itself.
          personal-site-clippy = craneLib.cargoClippy (commonArgs // {
            inherit cargoArtifacts;
            cargoClippyExtraArgs = "--all-targets -- --deny warnings";
          });

          # Check formatting
          personal-site-fmt = craneLib.cargoFmt { inherit src; };
        };

        # Packages / Artifacts
        packages.default = personal-site;
        packages.node-modules = node-modules;
        packages.bulma = node-modules;

        # Executable scripts
        apps.deploy = flake-utils.lib.mkApp {
          drv = pkgs-stable.writeShellScriptBin "deploy" ''
            ${pkgs-stable.wrangler}/bin/wrangler pages deploy --project-name=vyas-n --branch $GITHUB_REF_NAME ${personal-site}/
          '';
        };
        apps.default = flake-utils.lib.mkApp {
          drv = pkgs-stable.writeShellScriptBin "serve-app" ''
            ${pkgs-stable.python3Minimal}/bin/python3 -m http.server --directory ${personal-site} 8000
          '';
        };
        apps.debug = flake-utils.lib.mkApp {
          drv = pkgs-stable.writeShellScriptBin "debug" ''
            tree ${node-modules}
          '';
          # packages = with pkgs-stable; [ tree ];
        };

        # Development Environments
        devShells.default = craneLib.devShell {
          # Inherit inputs from checks.
          checks = self.checks.${system};

          shell = pkgs-stable.nushell;

          # Additional dev-shell environment variables can be set directly
          # MY_CUSTOM_DEVELOPMENT_VAR = "something else";

          # Extra inputs can be added here;
          # - cargo and rustc are provided by default from craneLib.
          # - This list of tools are intended for IDEs and dev shells
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
          ];
        };
      });
}
