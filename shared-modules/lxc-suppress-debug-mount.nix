{ config, pkgs, lib, ... }:
{
  systemd.suppressedSystemUnits = lib.mkAfter (if config.boot.isContainer
  then [ "sys-kernel-debug.mount" ]
  else [ ]);
}
