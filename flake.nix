{
  description = "A very basic flake";

  nixConfig = {
    substitute = "true";
    substituters = "https://cache.nixos.org/ https://nix-community.cachix.org/";
    trusted-public-keys = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    trusted-substituters = "https://nix-community.cachix.org/";
    trusted-users = "dwt";
  };

    # inputs is a set, declaring all of the flakes this flake depends on
  inputs = {
    # we of course want nixpkgs to provide stdenv, dependency packages, and
    # various nix functions
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-21.11";

    # we need the overlay at cargo2nix/overlay
    cargo2nix.url = "github:cargo2nix/cargo2nix/master";

    # we will need a rust toolchain at least to build our project
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.inputs.flake-utils.follows = "flake-utils";

    # convenience functions for writing flakes
    flake-utils.url = "github:numtide/flake-utils";

    fenix.url = "github:nix-community/fenix";
    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";
  };

  # outputs is a function that unsurprisingly consumes the inputs
  outputs = { self, nixpkgs, cargo2nix, flake-utils, rust-overlay, fenix, neovim-nightly, ... }:

     let
        crossSystem = "x86_64-pc-windows-gnu";
        pkgs = import nixpkgs {
          system = "x86_64-linux";
        };
        crossPkgs = import nixpkgs {
          system = "x86_64-linux";
          inherit crossSystem;
          overlays = [(import "${cargo2nix}/overlay")];
        };
        crossRustPkgs = crossPkgs.rustBuilder.makePackageSet' {
          rustChannel = "1.56.1";
          packageFun = import ./Cargo.nix;
          target = crossSystem;
        };
        secad-exe = (crossRustPkgs.workspace.secad { }).bin;
        crossOutput = {
            packages."${crossSystem}" = {
                "secad.exe" = secad-exe;
            };
            defaultPackage."${crossSystem}" = secad-exe;
        };
        mainOutputs =
            # Build the output set for each default system and map system sets into
            # attributes, resulting in paths such as:
            # nix build .#packages.x86_64-linux.<name>
            flake-utils.lib.eachDefaultSystem (system:

              # let-in expressions, very similar to Rust's let bindings.  These names
              # are used to express the output but not themselves paths in the output.
              let

                # create nixpkgs that contains rustBuilder from cargo2nix overlay
                pkgs = import nixpkgs {
                  inherit system;
                  overlays = [(import "${cargo2nix}/overlay")
                              fenix.overlay
                              rust-overlay.overlay
                              neovim-nightly.overlay];
                };

                # create the workspace & dependencies package set
                rustPkgs = pkgs.rustBuilder.makePackageSet' {
                  rustChannel = "1.56.1";
                  packageFun = import ./Cargo.nix;
                };

                vim = pkgs.callPackage ./vim.nix {};

              in rec {
                # this is the output (recursive) set (expressed for each system)

                devShell = pkgs.mkShell {
                  buildInputs = [ pkgs.cargo pkgs.rustc cargo2nix.packages.${system}.cargo2nix pkgs.rust-analyzer vim pkgs.rustfmt ];
                };

                # the packages in `nix build .#packages.<system>.<name>`
                packages = {
                  secad = (rustPkgs.workspace.secad {}).bin;
                  "secad.exe" = secad-exe;
                };

                # nix build
                defaultPackage = packages.secad;
              }
            );
    in
    pkgs.lib.attrsets.recursiveUpdate mainOutputs {};
}
