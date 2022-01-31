{
  description = "Flake for infrastructure as code";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-21.11;
    nixpkgs-unstable.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    flake-utils-plus.url = github:gytis-ivaskevicius/flake-utils-plus;
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = github:Mic92/sops-nix;
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
          oci-cli = channels.nixpkgs-unstable.oci-cli;
        })
      ];

      hosts.cloud.modules = with self.nixosModules; [
        common
        users
        hardware
        inputs.sops-nix.nixosModules.sops
        sops
        services
        drone
        gitea

        # oci-getserver
      ];

      hosts.oci = {
        system = "aarch64-linux";
        modules = with self.nixosModules; [
          common
          inputs.sops-nix.nixosModules.sops
          sops
          users
          hardware-oci
        ];
      };

      deploy.nodes = {
        cloud = {
          hostname = "foo.bar";
          fastConnection = false;
          profiles.system = {
            sshUser = "admin";
            path =
              inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.cloud;
            user = "root";
          };
        };
        oci = {
          hostname = "foo.bar";
          fastConnection = false;
          profiles.system = {
            sshUser = "admin";
            path =
              inputs.deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.oci;
            user = "root";
          };
        };
      };

      outputsBuilder = (channels:
        let pkgs = channels.nixpkgs; in
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
                inputs.deploy-rs.packages.${system}.deploy-rs
                age
                sops
              ];
          };
        });

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;
    };
}
