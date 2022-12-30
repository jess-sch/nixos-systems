{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  };
  outputs = { self, nixpkgs }: {
    nixosConfiguration =
      let
        sharedModules = builtins.map (name: import ./shared-modules/${name})
          (builtins.attrNames (builtins.readDir ./shared-modules));

        fileNames = builtins.attrNames (builtins.readDir ./hosts);
        hostNames = map (fileName: nixpkgs.lib.removeSuffix ".nix" fileName) fileNames;
        hosts = builtins.foldl'
          (set: hostName:
            set // { "${hostName}" = import ./hosts/${hostName}.nix; })
          { }
          hostNames;
        makeSystem = (name: module: nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = sharedModules ++ [ module { system.nixos.label = name; } ];
        });
      in
      builtins.mapAttrs makeSystem hosts;

    # Generate Hydra Jobs from NixOS Configurations
    hydraJobs = builtins.mapAttrs
      (host: config: {
        "${config.config.nixpkgs.system}" = config.config.system.build.toplevel;
      })
      self.nixosConfiguration;
  };
}
