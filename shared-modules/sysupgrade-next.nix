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
    cache = mkOption {
      type = types.str;
      description = "The binary cache from which to pull updates";
    };
    signedBy = mkOption {
      type = types.str;
      description = "The public key with which binaries are signed";
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
      cache = "http://hydra.v6.fyi";
      signedBy = "hydra.v6.fyi:FGmeG3K0tmxNJIFsjswRGhnHe3Apmkqcpw3CaOjqyCM=";
      stream.enable = true;
    };

    environment.etc."sysupgrade.json".text = with config.sysupgrade; builtins.toJSON {
      inherit broker topic cache signedBy;
      streamRandomizedDelaySec = config.sysupgrade.stream.randomizedDelaySec;
    };

    systemd.services.sysupgrade-stream = lib.mkIf config.sysupgrade.stream.enable {
      description = "Automatic Sysupgrades";

      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;

      serviceConfig.ExecStart = "${config.sysupgrade.package}/bin/sysupgrade stream";

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}
