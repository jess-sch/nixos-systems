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
      randomizedDelaySec = mkOption {
        type = types.int;
        default = 0;
        description = "Add a randomized delay before each automatic upgrade. The delay will be chosen between zero and this value.";
      };
    };
  };

  config = {
    # environment.systemPackages = [ config.sysupgrade.package ];

    sysupgrade = {
      broker = "ws://hydra.v6.fyi/mqtt";
      topic = "hydra/nixos-systems/main/${config.networking.hostName}.x86_64-linux";
      stream.enable = true;
    };

    environment.etc."sysupgrade.json".text = builtins.toJSON {
      broker = config.sysupgrade.broker;
      topic = config.sysupgrade.topic;
      streamRandomizedDelaySec = config.sysupgrade.stream.randomizedDelaySec;
    };

    systemd.services.sysupgrade-stream = lib.mkIf config.sysupgrade.stream.enable {
      description = "Automatic Sysupgrades";

      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;

      serviceConfig.Type = "oneshot";
      serviceConfig.ExecStart = "${config.sysupgrade.package}/bin/sysupgrade stream";

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}
