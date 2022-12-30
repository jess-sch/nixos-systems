{ config, pkgs, lib, ... }:
{
  nix.settings.substituters = [
    "http://hydra-cache.v6.fyi"
  ];
  nix.settings.trusted-public-keys = [
    "hydra-cache.v6.fyi:dphYk1Lmeks4xNxCCxNT0vYaWCqBunNaqNbfEQvL/6Q="
  ];
}
