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

  outputs = inputs @ {self, ...}: let
    supportedSystems = ["x86_64-linux"];
    config = {
      allowUnfree = true;
    };
    inherit (inputs.nixpkgs.lib) genAttrs attrValues;
  in {
    lib = import ./lib {inherit (inputs.nixpkgs) lib;};
    nixosModules = self.lib.exportModulesDir ./modules;

    nixosConfigurations.cloud = inputs.nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        pkgs = self.legacyPackages.${system};
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

    devShell = genAttrs supportedSystems (
      system: let
        pkgs = self.legacyPackages.${system};
        pre-commit = pkgs.writeShellScript "pre-commit" ''
          find . -name \*.nix -not -name deps.nix -exec alejandra {} \;
          nix flake check
          git add .
        '';
      in
        pkgs.mkShell {
          packages = attrValues {
            inherit
              (self.legacyPackages.${system})
              sops
              age
              ;
            inherit (inputs.deploy-rs.packages.${system}) deploy-rs;
            inherit (inputs.nixpkgs-unstable.legacyPackages.${system}) alejandra;
          };
          shellHook = ''
            ln -sf ${pre-commit.outPath} .git/hooks/pre-commit
          '';
        }
    );

    legacyPackages = genAttrs supportedSystems (
      system:
        import inputs.nixpkgs {
          inherit system config;
        }
    );
  };
}
