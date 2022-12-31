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

  checkType = "debug";

  nativeBuildInputs = with pkgs; [
    pkg-config
    cmake
  ];

  buildInputs = with pkgs; [
    openssl
  ];

  BIN_NIX_ENV = "${pkgs.nix}/bin/nix-env";
  BIN_SYSTEMCTL = "${pkgs.systemd}/bin/systemctl";
}
