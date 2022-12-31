{ config, pkgs, lib, ... }:
{
  nix.settings.substituters = [
    "http://hydra.v6.fyi"
  ];
  nix.settings.trusted-public-keys = [
    "hydra.v6.fyi:FGmeG3K0tmxNJIFsjswRGhnHe3Apmkqcpw3CaOjqyCM="
  ];
}
