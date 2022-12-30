{ config, pkgs, ... }: {
  nix.gc.options = "-d";
  users.users.root.password = "";
  services.rdnssd.enable = true;
  services.journald.extraConfig = "Storage=volatile";
  programs.bash.shellInit = ''
    unset HISTFILE
  '';
  services.getty.autologinUser = "root";
  system.stateVersion = config.system.nixos.release;
  boot.isContainer = true;
}