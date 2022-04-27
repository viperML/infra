{pkgs ? import ./default.nix {}}: let
  treefmt-cfg = pkgs.writeText "treefmt.toml" ''
    [formatter.nix]
    command = "alejandra"
    includes = ["*.nix"]
  '';
  pre-commit = pkgs.writeShellScript "pre-commit" ''
    treefmt --config-file ${treefmt-cfg} --tree-root .
    nix flake check
    git add .
  '';
in
  pkgs.mkShell {
    name = "development-shell";

    packages = with pkgs; [
      sops
      age
      deploy-rs
      treefmt
      alejandra
    ];

    shellHook = ''
      ln -sf ${pre-commit} .git/hooks/pre-commit
    '';
  }
