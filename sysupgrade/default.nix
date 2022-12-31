{ pkgs ? import <nixpkgs> { } }:
let
  pkgmeta = (builtins.fromTOML (builtins.readFile ./Cargo.toml)).package;
in
pkgs.rustPlatform.buildRustPackage {
  pname = pkgmeta.name;
  version = pkgmeta.version;
  meta.description = pkgmeta.description;
  meta.maintainers = pkgmeta.authors;

  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;

  buildInputs = with pkgs; [ ];
  BIN_NIX_DIR = "${pkgs.nix}/bin";
}
