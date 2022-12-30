{ config, lib, pkgs, ... }:
{
  boot.isContainer = true;
  systemd.suppressedSystemUnits = [ "sys-kernel-debug.mount" ];
}