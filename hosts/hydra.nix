{ config, pkgs, lib, ... }:
{
  boot.isContainer = true;

  networking = {
    hostName = "hydra";
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    firewall.enable = true;
    firewall.allowedTCPPorts = [ 80 ];
  };

  services.rdnssd.enable = true;

  services.getty.autologinUser = "root";
  users.allowNoPasswordLogin = true;
  security.sudo.enable = false;

  services.journald.extraConfig = "Storage=volatile";
  programs.bash.shellInit = ''
    unset HISTFILE
  '';

  services.mosquitto = {
    enable = true;
    logType = [ "error" ];
    listeners = [
      {
        address = "/var/run/mosquitto/mqtt.sock";
        port = 0;
        acl = [ "topic readwrite #" ];
        settings.allow_anonymous = true;
      }
      {
        address = "::";
        port = 1883;
        acl = [ "topic read #" ];
        settings.allow_anonymous = true;
      }
    ];
  };

  environment.systemPackages = with pkgs; [ mosquitto ];

  services.hydra = {
    enable = true;
    hydraURL = "http://hydra.v6.fyi";
    notificationSender = "hydra@localhost";
    buildMachinesFiles = [ ];
    useSubstitutes = true;
    extraConfig =
      let
        command = pkgs.writeShellScript "hydra-build-hook" ''
          SUCCESS=$(${pkgs.jq}/bin/jq '.buildStatus==0' < $HYDRA_JSON)
          if [ "$SUCCESS" = "true" ]; then
            TOPIC=$(${pkgs.jq}/bin/jq -r '"\(.project)/\(.jobset)/\(.job)"' < $HYDRA_JSON)
            NIX_OUT_PATH=$(${pkgs.jq}/bin/jq -r '.outputs[0].path' < $HYDRA_JSON)
            ${pkgs.mosquitto}/bin/mosquitto_pub --unix /var/run/mosquitto/mqtt.sock --retain -t "$TOPIC" -m "$NIX_OUT_PATH"
          fi
        '';
      in
      ''
        <runcommand>
          job = *:*:*
          command = ${command}
        </runcommand>
      '';
  };

  users.users.hydra-queue-runner.extraGroups = [ "mosquitto" ];

  services.nix-serve.enable = true;
  systemd.services.nix-serve.serviceConfig.Environment = "\"NIX_SECRET_KEY_FILE=/var/cache-priv-key.pem\"";

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
