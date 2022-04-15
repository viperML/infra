{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  time.timeZone = "UTC";
  system.stateVersion = "21.11";
  system.configurationRevision = inputs.self.rev or null;

  environment.systemPackages = with pkgs; [
    fish
    htop
  ];

  nix = {
    package =
      if lib.versionAtLeast pkgs.nix.version pkgs.nix_2_4.version
      then pkgs.nix
      else pkgs.nix_2_4;

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
