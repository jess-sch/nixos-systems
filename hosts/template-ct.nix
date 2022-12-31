{ config, pkgs, lib, ... }: {
  boot.isContainer = true;

  services.rdnssd.enable = true;
  networking.useDHCP = true;

  users.allowNoPasswordLogin = true;
  services.journald.extraConfig = "Storage=volatile";
  services.getty.autologinUser = "root";
  programs.bash.shellInit = ''
    unset HISTFILE
  '';

  documentation.enable = false;
  nix.settings.keep-build-log = false;

  security.sudo.enable = false;
  networking.firewall.enable = false;
  environment.defaultPackages = lib.mkForce [ ];
  nix.gc.automatic = false;
  sysupgrade.stream.enable = false;

  system.stateVersion = config.system.nixos.release;
}
