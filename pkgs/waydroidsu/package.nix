{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  dbus,
  openssl,
}:

rustPlatform.buildRustPackage rec {
  pname = "waydroidsu";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "mistrmochov";
    repo = "WaydroidSU";
    rev = version;
    hash = "sha256-ICC/lTUSUpeg/RZOfLJzplt3aQBXlNg1ng8yANGVMgA=";
  };

  cargoHash = "sha256-kweqiD7UyS8Tm9bPvjGx6V91uUf2xLQtxw5L5frFuOw=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    dbus
    openssl
  ];

  meta = with lib; {
    description = "CLI Magisk manager and installer for Waydroid";
    homepage = "https://github.com/mistrmochov/WaydroidSU";
    license = licenses.gpl3Only;
    mainProgram = "wsu";
    platforms = platforms.linux;
  };
}
