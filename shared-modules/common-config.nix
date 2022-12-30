{ config, pkgs, lib, ... }:{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc.automatic = lib.mkDefault true;
  users.mutableUsers = lib.mkDefault false;
}