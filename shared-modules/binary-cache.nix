{ config, pkgs, lib, ... }:
{
  nix.settings.substituters = [
    "https://cache.nixos.org"
    "http://hydra-cache.v6.fyi"
  ];
  nix.settings.trusted-public-keys = [
    "hydra-cache.v6.fyi:dphYk1Lmeks4xNxCCxNT0vYaWCqBunNaqNbfEQvL/6Q="
  ];

  environment.systemPackages = lib.mkAfter [
    (pkgs.writeShellScriptBin "sysupgrade" ''
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
        "http://hydra.v6.fyi/job/nixos-systems/main/$hostname.${config.nixpkgs.system}/latest-finished" | ${pkgs.jq}/bin/jq -r '.buildoutputs.out.path')
      if [ "$system_path" = "null" ]; then
        echo "Error: There is no configuration for $hostname"
        exit 1
      fi
      echo "Next generation: $system_path"
      ${config.nix.package}/bin/nix-env --profile /nix/var/nix/profiles/system --set "$system_path"
      /nix/var/nix/profiles/system/bin/switch-to-configuration $1
    '')
  ];
}
