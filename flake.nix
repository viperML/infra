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

  outputs = inputs @ {self, ...}: let
    supportedSystems = ["x86_64-linux"];
    config = {
      allowUnfree = true;
    };
    inherit (inputs.nixpkgs.lib) genAttrs attrValues;
  in {
    nixosConfigurations.cloud = inputs.nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      pkgs = self.legacyPackages.${system};
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
        ./modules/autoUpgrade.nix
        ./modules/searx
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

    devShells."x86_64-linux".default = let
      system = "x86_64-linux";
      pkgs = self.legacyPackages.${system};
      pre-commit = pkgs.writeShellScript "pre-commit" ''
        find . -name \*.nix -not -name deps.nix -exec alejandra {} \;
        nix flake check
        git add .
      '';
    in
      pkgs.mkShell {
        name = "development-shell";
        packages = attrValues {
          inherit
            (pkgs)
            sops
            age
            ;
          inherit (inputs.deploy-rs.packages.${system}) deploy-rs;
          inherit (inputs.nixpkgs-unstable.legacyPackages.${system}) alejandra;
        };
        shellHook = ''
          ln -sf ${pre-commit.outPath} .git/hooks/pre-commit
        '';
      };

    legacyPackages = genAttrs supportedSystems (
      system:
        import inputs.nixpkgs {
          inherit system config;
          overlays = [
            (import ./overlay)
          ];
        }
    );
  };
}
