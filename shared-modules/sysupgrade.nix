{ config, pkgs, lib, ... }:
let
  sysupgradePkg = pkgs.writeShellScriptBin "sysupgrade" ''
    if [ -z "$1" ]; then
      echo "Usage: sysupgrade (switch/boot/...) [new-hostname]"
      exit 1
    fi
    if [ -z "$2" ]; then
      hostname="${config.networking.hostName}"
    else
      hostname=$2
      echo "New hostname: $hostname"
      echo "If this was a mistake, cancel and revert by running 'sysupgrade switch ${config.networking.hostName}'"
    fi
    system_path=$(${pkgs.curl}/bin/curl --location --header "Accept: application/json" \
      "http://hydra.v6.fyi/hydra/job/nixos-systems/main/$hostname.${config.nixpkgs.system}/latest-finished" | ${pkgs.jq}/bin/jq -r '.buildoutputs.out.path')
    if [ "$system_path" = "null" ]; then
      echo "Error: There is no configuration for $hostname"
      exit 1
    fi
    echo "Next generation: $system_path"
    ${config.nix.package}/bin/nix-env --profile /nix/var/nix/profiles/system --set "$system_path"
    /nix/var/nix/profiles/system/bin/switch-to-configuration $1
  '';
in
{
  options.autoSysupgrade = {
    enable = lib.mkOption {
      default = true;
      description = "Whether to enable automatic sysupgrades.";
      type = lib.types.bool;
    };
    schedule = lib.mkOption {
      type = lib.types.str;
      description = "The value of the OnCalendar= timer attribute. Every five minutes by default";
      default = "*:0/5";
    };
  };

  config = {
    environment.systemPackages = lib.mkAfter [ sysupgradePkg ];

    systemd.services.sysupgrade = lib.mkIf config.autoSysupgrade.enable {
      description = "Automatic Sysupgrades";

      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;

      serviceConfig.Type = "oneshot";
      serviceConfig.ExecStart = "${sysupgradePkg}/bin/sysupgrade switch";

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      startAt = config.autoSysupgrade.schedule;
    };
  };
}
