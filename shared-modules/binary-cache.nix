{ config, pkgs, lib, ... }:
{
  nix.settings.substituters = [
    "http://hydra.v6.fyi"
  ];
  nix.settings.trusted-public-keys = [
    "hydra.v6.fyi:hHQwupF105WgjbkY4AYVnRafW+b++kHrDmXXnyZEK9o="
  ];
}
