{ config, pkgs, ... }:
{
  nix.settings.substituters = [
    "https://cache.nixos.org"
    "http://hydra-cache.v6.fyi"
  ];
  nix.settings.trusted-public-keys = [
    "hydra-cache.v6.fyi:dphYk1Lmeks4xNxCCxNT0vYaWCqBunNaqNbfEQvL/6Q="
  ];

  environment.systemPackages = [( pkgs.writeShellScriptBin "sysupgrade" ''
    if [ -z "$1" ]; then
      hostname="${config.networking.hostName}"
    else
      hostname=$1
    fi
    system_path=$(${pkgs.curl}/bin/curl --location --header "Accept: application/json" \
      "http://hydra.v6.fyi/job/nixos-systems/main/$hostname.${config.nixpkgs.system}/latest-finished" | ${pkgs.jq}/bin/jq -r '.buildoutputs.out.path')
    echo "Next generation: $system_path"
    ${config.nix.package}/bin/nix-env --profile /nix/var/nix/profiles/system --set "$system_path"
    /nix/var/nix/profiles/system/bin/switch-to-configuration switch
  '')];
}