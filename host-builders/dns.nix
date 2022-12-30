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
    resolveLocalQueries = false;
    settings = {
      remote-control.control-enable = true;
      forward-zone = [{
        name = ".";
        forward-addr = "2a06:98c1:54::3:b4c6";
      }];
      server.module-config = "\"" + (if dns64 then "dns64 " else "") + "validator iterator\"";
      server.dns64-prefix = "64:ff9b::/96";
    };
  };
}
