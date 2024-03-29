{ config, pkgs, lib, ... }:
{
  boot.isContainer = true;

  networking = {
    tempAddresses = "disabled";
    useDHCP = false;
    interfaces.eth0 = {};
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
        address = "::1";
        port = 9001;
        acl = [ "topic read #" ];
        settings.allow_anonymous = true;
        settings.protocol = "websockets";
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
            ${pkgs.skopeo}/bin/skopeo inspect docker-archive:$NIX_OUT_PATH 1>/dev/null 2>/dev/null && {
              echo "Uploading container"
              ${pkgs.skopeo}/bin/skopeo --dest-tls-verify=false docker-archive:$NIX_OUT_PATH docker://localhost:5001/$TOPIC
            } || echo "Not a container, skipping upload to registry."
            ${pkgs.mosquitto}/bin/mosquitto_pub --unix /var/run/mosquitto/mqtt.sock --retain -t "hydra/$TOPIC" -m "$NIX_OUT_PATH"
          fi
        '';
      in
      ''
        using_frontend_proxy 1
        <runcommand>
          job = *:*:*
          command = ${command}
        </runcommand>
      '';
  };

  users.users.hydra-queue-runner.extraGroups = [ "mosquitto" ];

  services.nix-serve.enable = true;
  systemd.services.nix-serve.serviceConfig.Environment = "\"NIX_SECRET_KEY_FILE=/var/cache-priv-key.pem\"";

  services.dockerRegistry = {
    enable = true;
    enableDelete = true;
    enableGarbageCollect = true;
    port = 5001;
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
    virtualHosts."_".locations = {
      "/".proxyPass = "http://127.0.0.1:3000";
      "/nix-cache-info".proxyPass = "http://127.0.0.1:5000";
      "~ \\.(narinfo|nar)$".proxyPass = "http://127.0.0.1:5000";
      "= /mqtt" = {
        proxyPass = "http://[::1]:9001/";
        proxyWebsockets = true;
        extraConfig = "proxy_read_timeout 7d;";
      };
      "/v2/" = {
        proxyPass = "http://127.0.0.1:5001/v2/";
        extraConfig = ''
          limit_except GET HEAD {
            deny all;
          }
        '';
      };
    };
  };

  system.stateVersion = "22.11";
}
