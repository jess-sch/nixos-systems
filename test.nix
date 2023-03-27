{ pkgs ? import <nixpkgs> {} }:
pkgs.dockerTools.buildLayeredImage {
  name = "test";
}