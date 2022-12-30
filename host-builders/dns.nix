name: { config, pkgs, lib, ... }:
let
  dns64 = lib.hasPrefix "dns64" name;
in
{
  networking.hostName = name;
  nix.gc.options = "-d";
  services.rdnssd.enable = true;
  services.journald.extraConfig = "Storage=volatile";
  programs.bash.shellInit = ''
    unset HISTFILE
  '';
  services.getty.autologinUser = "root";
  users.allowNoPasswordLogin = true;

  system.stateVersion = config.system.nixos.release;
  boot.isContainer = true;

  services.unbound = {
    enable = true;
    localControlSocketPath = "/run/unbound/unbound.ctl";
    settings.remote-control.control-enable = true;
    settings.forward-zone = [{
      name = ".";
      forward-addr = "2a06:98c1:54::3:b4c6";
    }];
    settings.module-config = (if dns64 then "dns64 " else "") + "validator iterator";
  };
} // (if dns64 then {
  services.unbound.settings.dns64-prefix = "64:ff9b::/96";
} else { })
