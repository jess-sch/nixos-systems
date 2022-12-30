{ config, pkgs, lib, ... }: {
  boot.isContainer = true;
  networking.hostName = "template-ct";

  services.rdnssd.enable = true;
  networking.useDHCP = true;

  users.allowNoPasswordLogin = true;
  services.journald.extraConfig = "Storage=volatile";
  services.getty.autologinUser = "root";
  programs.bash.shellInit = ''
    unset HISTFILE
  '';

  security.sudo.enable = false;
  networking.firewall.enable = false;
  environment.defaultPackages = lib.mkForce [];

  system.stateVersion = config.system.nixos.release;
}
