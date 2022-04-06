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
    #nixpkgs.url = "github:nixos/nixpkgs?ref=release-21.11";
    nixpkgs.url = "github:nixos/nixpkgs/master";

    # we need the overlay at cargo2nix/overlay
    cargo2nix.url = "github:cargo2nix/cargo2nix/master";
    cargo2nix.inputs.rust-overlay.follows = "rust-overlay";

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
        # These are different because nix and Rust expect different triples for the same system
        rustCrossSystem = "x86_64-pc-windows-gnu";
        nixCrossSystem = "x86_64-w64-mingw32";
        crossPkgs = import nixpkgs {
          system = "x86_64-linux";
          crossSystem = {
            config = nixCrossSystem;
          };
          # I don't need all the other stuff for the cross-compiled version
          overlays = [(import "${cargo2nix}/overlay") rust-overlay.overlay];
        };
        crossRustPkgs = crossPkgs.rustBuilder.makePackageSet' {
          rustChannel = "1.57.0";
          packageFun = import ./Cargo.nix;
          target = rustCrossSystem;
        };
        # This is where non-Rust runtime dependences will need to go
        cross-secad-exe-drv = (crossRustPkgs.workspace.secad { }).overrideAttrs (self: {
            buildInputs = self.buildInputs ++ [ crossPkgs.windows.pthreads ];
        });
        cross-secad-exe = cross-secad-exe-drv.bin;
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
                  rustChannel = "1.57.0";
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
                  # This cross-compiled version isn't build using the current value for hostSystem. That'll be
                  # fine until it bites me when I try to build on something different.
                  "secad.exe" = cross-secad-exe;
                };

                # nix build
                defaultPackage = packages.secad;
              }
            );
    in
    mainOutputs;
}
