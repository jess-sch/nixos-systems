{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  };
  outputs = { self, nixpkgs }: {
    nixosConfiguration =
      let
        sharedModules = import ./shared-modules;
      in
      {
        "dns-a" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = sharedModules ++ [ (import ./hosts/dns-a.nix) ];
        };
        "hydra" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = sharedModules ++ [ (import ./hosts/hydra.nix) ];
        };
      };

    # Generate Hydra Jobs from NixOS Configurations
    hydraJobs = builtins.mapAttrs
      (host: config: {
        "${config.config.nixpkgs.system}" = config.config.system.build.toplevel;
      })
      self.nixosConfiguration;
  };
}
