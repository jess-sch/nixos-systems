{ config, pkgs, lib, ... }:
{
  options.sysupgrade = with lib; {
    package = mkOption {
      type = types.package;
      description = "The sysupgrade package";
      default = import ../sysupgrade { inherit pkgs; };
    };
    broker = mkOption {
      type = types.str;
      description = "The broker at which to listen for updates";
    };
    topic = mkOption {
      type = types.str;
      description = "The topic at which to listen for updates";
    };
    stream = {
      enable = lib.mkOption {
        default = true;
        description = "Whether to enable watching for updates.";
        type = lib.types.bool;
      };
      switch = mkOption {
        type = types.bool;
        default = true;
        description = "When enabled, switch to the new configurations. When disabled, activate them on boot instead";
      };
    };
  };

  config = {
    environment.systemPackages = [ config.sysupgrade.package ];

    sysupgrade = {
      broker = "ws://hydra.v6.fyi/mqtt";
      topic = "hydra/nixos-systems/main/${config.networking.hostName}.x86_64-linux";
    };

    systemd.services.sysupgrade-boot = {
      description = "Enable the latest generation on next boot";
      serviceConfig.Type = "oneshot";
      serviceConfig.ExecStart = "/nix/var/nix/profiles/system/bin/switch-to-configuration boot";
      serviceConfig.TimeoutStartSec = "15min";
      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;
    };

    systemd.services.sysupgrade-switch = {
      description = "Switch to the latest configuration";
      serviceConfig.Type = "oneshot";
      serviceConfig.ExecStart = "/nix/var/nix/profiles/system/bin/switch-to-configuration switch";
      serviceConfig.TimeoutStartSec = "15min";
      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;
    };

    systemd.services.sysupgrade-once = {
      description = "Install system updates";
      serviceConfig.ExecStart = with config.sysupgrade;
        let
          action = if stream.switch then "switch" else "boot";
        in
        "${config.sysupgrade.package}/bin/sysupgrade --mode once --broker '${broker}' --topic '${topic}' --action sysupgrade-${action}.service";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    systemd.services.sysupgrade-stream = lib.mkIf config.sysupgrade.stream.enable {
      description = "Watch for system updates";
      serviceConfig.ExecStart = with config.sysupgrade;
        let
          action = if stream.switch then "switch" else "boot";
        in
        "${config.sysupgrade.package}/bin/sysupgrade --mode stream --broker '${broker}' --topic '${topic}' --action sysupgrade-${action}.service";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}
