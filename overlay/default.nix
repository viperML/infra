final: prev: let
  inherit (prev) callPackage fetchFromGitHub;
  my-httpx-socks = prev.python3Packages.callPackage ./httpx-socks.nix {};
in {
  # searx = prev.searx.overrideAttrs (prevAttrs: {
  #   version = "unstable-2022-03-05";
  #   src = fetchFromGitHub {
  #     owner = "searx";
  #     repo = "searx";
  #     rev = "f231d79a5ddd2ff211e401fe6ea2250325df116f";
  #     sha256 = "06bxzfnvv3dncabp1z9qvy67y5n6drj6h9shsqaxzv5mzijqbn4s";
  #   };
  #   patches = [];
  #   propagatedBuildInputs =
  #     prevAttrs.propagatedBuildInputs
  #     ++ (with final.python3Packages; [
  #       uvloop
  #       setproctitle
  #       httpx
  #       my-httpx-socks
  #     ]);
  # });
}
