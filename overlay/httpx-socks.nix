# https://github.com/NixOS/nixpkgs/blob/bacbfd713b4781a4a82c1f390f8fe21ae3b8b95b/pkgs/development/python-modules/httpx-socks/default.nix
# No checks
{
  lib,
  async-timeout,
  buildPythonPackage,
  curio,
  fetchFromGitHub,
  flask,
  httpcore,
  httpx,
  pytest-asyncio,
  pytest-trio,
  pytestCheckHook,
  python-socks,
  pythonOlder,
  sniffio,
  trio,
  yarl,
}:
buildPythonPackage rec {
  pname = "httpx-socks";
  version = "0.4.1";
  disabled = pythonOlder "3.6";

  src = fetchFromGitHub {
    owner = "romis2012";
    repo = pname;
    rev = "v${version}";
    sha256 = "1rz69z5fcw7d5nzy5q2q0r9gxrsqijgpg70cnyr5br6xnfgy01ar";
  };

  propagatedBuildInputs = [
    async-timeout
    curio
    httpcore
    httpx
    python-socks
    sniffio
    trio
  ];

  checkInputs = [
    flask
    pytest-asyncio
    pytest-trio
    pytestCheckHook
    yarl
  ];

  doCheck = false;

  meta = with lib; {
    description = "Proxy (HTTP, SOCKS) transports for httpx";
    homepage = "https://github.com/romis2012/httpx-socks";
    license = licenses.asl20;
    maintainers = with maintainers; [fab];
  };
}
