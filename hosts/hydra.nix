{ config, pkgs, lib, ... }:
{
  networking = {
    hostName = "hydra";
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    firewall.enable = true;
    firewall.allowedTCPPorts = [ 80 ];
  };

  services.journald.extraConfig = "Storage=volatile";
  services.getty.autologinUser = "root";
  programs.bash.shellInit = ''
    unset HISTFILE
  '';

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };

  systemd.sockets.sshd.enable = false;
  services.openssh = {
    enable = true;
    allowSFTP = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
  };

  services.rdnssd.enable = true;
  users.users.root.password = "";

  boot.isContainer = true;

  services.hydra = {
    enable = true;
    hydraURL = "http://hydra.v6.fyi";
    notificationSender = "hydra@localhost";
    buildMachinesFiles = [ ];
    useSubstitutes = true;
  };

  services.nix-serve = {
    enable = true;
    secretKeyFile = "/var/cache-priv-key.pem";
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    logError = "stderr error";
    commonHttpConfig = ''
      access_log off;
    '';
    virtualHosts."hydra.v6.fyi".locations."/" = {
      proxyPass = "http://127.0.0.1:3000";
      proxyWebsockets = true;
    };
    virtualHosts."hydra-cache.v6.fyi".locations."/" = {
      proxyPass = "http://127.0.0.1:5000";
      proxyWebsockets = true;
    };
  };

  system.stateVersion = "22.11";
}
