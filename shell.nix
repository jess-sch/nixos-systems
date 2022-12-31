{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    git
    openssh
    nixpkgs-fmt
    rustfmt
    clippy
    rustc
    cargo
    gcc
    pkg-config
    cmake
    openssl
  ];

  RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
}
