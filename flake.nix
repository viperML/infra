{
  description = "NixOS flake for my server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-flakes = {
      url = "github:viperML/nixos-flakes";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    deploy-rs,
    ...
  }: let
    supportedSystems = ["x86_64-linux"];
    config = {
      allowUnfree = true;
    };
    genSystems = nixpkgs.lib.genAttrs supportedSystems;
    pkgsFor = system: self.legacyPackages.${system};
  in {
    nixosConfigurations.cloud = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = pkgsFor system;
      specialArgs = {inherit inputs;};
      modules = [
        ./modules/common.nix
        inputs.nixos-flakes.nixosModules.channels-to-flakes
        ./modules/users.nix
        inputs.sops-nix.nixosModules.sops
        ./modules/hardware-cloud.nix

        ./modules/services.nix
        ./modules/docker.nix
        ./modules/drone.nix
        ./modules/gitea.nix
        # TODO
        # ./modules/autoUpgrade.nix
        ./modules/searx
        # ./modules/cache.nix
      ];
    };

    deploy.nodes.cloud = {
      hostname = "cloud";
      fastConnection = false;
      profiles.system = {
        sshUser = "admin";
        path =
          deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.cloud;
        user = "root";
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

    devShells = genSystems (system: {
      default = import ./shell.nix {
        pkgs = pkgsFor system;
      };
    });

    legacyPackages = genSystems (system:
      (import nixpkgs {
        inherit system config;
        # overlays = [
        #   (import ./overlay)
        # ];
      })
      // {
        inherit (deploy-rs.packages.${system}) deploy-rs;
        inherit
          (inputs.nixpkgs-unstable.legacyPackages.${system})
          alejandra
          treefmt
          ;
      });
  };
}
