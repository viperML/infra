{ config, pkgs, inputs, ... }:
{
  time.timeZone = "UTC";
  system.stateVersion = "21.11";
  system.configurationRevision = inputs.self.rev or null;

  environment.systemPackages = with pkgs; [
    fup-repl
    fish
    htop
  ];


  nix = {
    package = pkgs.nixFlakes;

    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    generateNixPathFromInputs = true;
    linkInputs = true;
    generateRegistryFromInputs = true;
  };
}
