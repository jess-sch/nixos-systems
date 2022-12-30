{ config, pkgs, ... }: {
  nix.gc.automatic = true;
  nix.gc.options = "-d";
  users.mutableUsers = false;
  users.users.root.password = "";
  services.rdnssd.enable = true;
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  services.journald.extraConfig = "Storage=volatile";
  programs.bash.shellInit = ''
    unset HISTFILE
  '';
  services.getty.autologinUser = "root";
  system.stateVersion = config.system.nixos.release;
  boot.isContainer = true;
}
