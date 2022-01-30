{ stdenv }:
stdenv.mkDerivation {
  src = ./.;
  pname = "oci-getserver";
  version = "latest";
  installPhase = ''
    mkdir -p $out
    cp $src/* $out
  '';
}
