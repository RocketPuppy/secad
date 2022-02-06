{
  description = "A very basic flake";

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
  };

  # outputs is a function that unsurprisingly consumes the inputs
  outputs = { self, nixpkgs, cargo2nix, flake-utils, rust-overlay, ... }:

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
                      rust-overlay.overlay];
        };

        # create the workspace & dependencies package set
        rustPkgs = pkgs.rustBuilder.makePackageSet' {
          rustChannel = "1.56.1";
          packageFun = import ./Cargo.nix;
        };

      in rec {
        # this is the output (recursive) set (expressed for each system)

        devShell = pkgs.mkShell {
          buildInputs = [ pkgs.cargo pkgs.rustc cargo2nix.packages.${system}.cargo2nix ];
        };

        # the packages in `nix build .#packages.<system>.<name>`
        packages = {
          secad = (rustPkgs.workspace.secad {}).bin;
        };

        # nix build
        defaultPackage = packages.secad;
      }
    );
}
