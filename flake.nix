{
  description = "NixOS flake for my server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
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

  outputs = inputs@{ self, nixpkgs, flake-utils-plus, ... }:
    let
      nixosModules = flake-utils-plus.lib.exportModules (
        nixpkgs.lib.mapAttrsToList (name: value: ./modules/${name}) (builtins.readDir ./modules)
      );
    in
    flake-utils-plus.lib.mkFlake {
      inherit self inputs nixosModules;

      channelsConfig.allowUnfree = true;

      channels.nixpkgs.overlaysBuilder = channels: [
        (final: prev: {
          inherit (inputs.nixpkgs-unstable)
          oci-cli
          ;
        })
      ];

      hosts.cloud.modules = with self.nixosModules; [
        common
        users
        inputs.sops-nix.nixosModules.sops
        sops
        hardware-cloud

        services
        docker
        drone
        gitea
        autoUpgrade
      ];

      deploy.nodes = {
        cloud = {
          hostname = "cloud";
          fastConnection = false;
          profiles.system = {
            sshUser = "admin";
            path =
              inputs.deploy-rs.lib.${self.nixosConfigurations.cloud.system}.activate.nixos self.nixosConfigurations.cloud;
            user = "root";
          };
        };
      };

      outputsBuilder = channels:
        let
          pkgs = channels.nixpkgs;
        in
        {
          devShell = channels.nixpkgs.mkShell {
            name = "development-shell";
            buildInputs =
              let
                make-vm = pkgs.writeShellScriptBin "make-vm" ''
                  set -eux -o pipefail
                  rm *.qcow2 || pass
                  nix build .#nixosConfigurations.cloud.config.system.build.vm
                  ./result/bin/run-cloud-vm
                '';
              in
              with pkgs; [
                make-vm
                age
                sops
                inputs.deploy-rs.packages.${pkgs.system}.deploy-rs
              ];
          };
        };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;
    };
}
