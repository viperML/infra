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
  };

  outputs =
    inputs @
    {
      self,
      nixpkgs,
      ...
    }:
    let
      supportedSystems = ["x86_64-linux" "aarch64-linux"];
    in {
      lib = import ./lib { inherit (nixpkgs) lib; };
      nixosModules = self.lib.exportModulesDir ./modules;

      nixosConfigurations.cloud = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          pkgs = self.pkgs.${system};
        };
        modules = with self.nixosModules; [
          common
          channels-to-flakes
          users
          inputs.sops-nix.nixosModules.sops
          sops
          hardware-cloud

          services
          docker
          drone
          gitea
          autoUpgrade
          searx
        ];
      };

      deploy.nodes.cloud = {
        hostname = "cloud";
        fastConnection = false;
        profiles.system = {
          sshUser = "admin";
          path =
            inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.cloud;
          user = "root";
        };
      };

      devShell = nixpkgs.lib.genAttrs supportedSystems (
        system: let
          pkgs = nixpkgs.legacyPackages.${system};
        in
          pkgs.mkShell {
            packages = with pkgs; [sops age];
          }
      );

      pkgs = nixpkgs.lib.genAttrs supportedSystems (
        system:
          import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          }
      );
    };
}
