{ config, pkgs, lib, ... }: {
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc.automatic = lib.mkDefault true;
  nix.gc.options = lib.mkDefault "--delete-older-than 7d";

  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  users.mutableUsers = lib.mkDefault false;

  networking.domain = lib.mkDefault "v6.fyi";
}
