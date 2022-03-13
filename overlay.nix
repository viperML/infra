final: prev: let
  inherit (prev) callPackage fetchFromGitHub;
in {
  python3 = prev.python3.override {
    packageOverrides = python3-final: python3-prev: {
      httpx-socks = python3-prev.httpx-socks.overrideAttrs (prevAttrs: {
        doCheck = false;
      });
    };
  };

  searx = prev.searx.overrideAttrs (prevAttrs: {
    version = "unstable-2022-03-05";
    src = fetchFromGitHub {
      owner = "searx";
      repo = "searx";
      rev = "f231d79a5ddd2ff211e401fe6ea2250325df116f";
      sha256 = "06bxzfnvv3dncabp1z9qvy67y5n6drj6h9shsqaxzv5mzijqbn4s";
    };
    patches = [];
    propagatedBuildInputs =
      prevAttrs.propagatedBuildInputs
      ++ (with final.python3Packages; [
        uvloop
        setproctitle
        httpx
        httpx-socks
      ]);
  });
}
