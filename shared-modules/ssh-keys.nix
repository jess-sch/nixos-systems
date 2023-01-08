{ config, pkgs, lib, ... }:
{
  users.users.root.openssh.authorizedKeys.keys = lib.mkAfter [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEybDg4wF3vNPGc66lrziDKJWUksXyCx039kEUoy50DM jess@Jess-ThinkPad"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMgHY81rSqB+JUi00XilNixn4udc4x5WMzvqK5yRyPQY Jess-Inspiron"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN5OBUw9fCqnRVZfy/A4OXcJU5Ilk6+/lGHtjA5b17RG Jess-MacMini"
  ];
}
