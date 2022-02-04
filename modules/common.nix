{ config, pkgs, inputs, ... }:
{
  time.timeZone = "UTC";
  system.stateVersion = "21.11";
  system.configurationRevision = (if inputs.self ? rev then inputs.self.rev else null);

  environment.systemPackages = with pkgs; [
    fup-repl
    fish
    htop
  ];

  sops.age.keyFile = "/secrets/age/keys.txt";

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
