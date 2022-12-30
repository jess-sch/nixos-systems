{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  };
  outputs = { self, nixpkgs }: {
    nixosConfiguration =
      let
        sharedModules = import ./shared-modules;
      in
      builtins.mapAttrs
        (name: module: nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = sharedModules ++ [ module ];
        })
        {
          "dns-a" = import ./hosts/dns-a.nix;
          "hydra" = import ./hosts/hydra.nix;
          "template-ct" = import ./hosts/template-ct.nix;
        };

    # Generate Hydra Jobs from NixOS Configurations
    hydraJobs = builtins.mapAttrs
      (host: config: {
        "${config.config.nixpkgs.system}" = config.config.system.build.toplevel;
      })
      self.nixosConfiguration;
  };
}
