{ config, pkgs, ... }: {
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

  system.stateVersion = config.system.nixos.release;
}
