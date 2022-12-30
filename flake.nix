{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  };
  outputs = { self, nixpkgs }: {
    nixosConfiguration = let
      lxcFixups = import ./lxc-fixups.nix;
    in {
      "dns-a" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ lxcFixups ({ config, pkgs, ... }: {
          nix.gc.automatic = true;
          nix.gc.options = "-d";
          users.mutableUsers = false;
          users.users.root.password = "";
          services.rdnssd.enable = true;
          time.timeZone = "Europe/Berlin";
          i18n.defaultLocale = "en_US.UTF-8";
          services.journald.extraConfig = "Storage=volatile";
          programs.bash.shellInit = ''
            unset HISTFILE
          '';
          services.getty.autologinUser = "root";
          system.stateVersion = config.system.nixos.release;
        })];
      };
      "hydra" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [(import ./hydra.nix)];
      };
    };

    # Generate Hydra Jobs from NixOS Configurations
    hydraJobs = builtins.mapAttrs (host: config: {
      "${config.config.nixpkgs.system}" = config.config.system.build.toplevel;
    }) self.nixosConfiguration;
  };
}