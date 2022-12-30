{ config, pkgs, lib, ... }:
{
  users.users.root.openssh.authorizedKeys.keys = lib.mkAfter [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINryFJRei4o1Q0jHwIRZNQ9AmDzTU8dnNmTckkNqd8zE Jess-ThinkPad"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMgHY81rSqB+JUi00XilNixn4udc4x5WMzvqK5yRyPQY Jess-Inspiron"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN5OBUw9fCqnRVZfy/A4OXcJU5Ilk6+/lGHtjA5b17RG Jess-MacMini"
  ];
}
