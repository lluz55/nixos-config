{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
}:

stdenv.mkDerivation rec {
  pname = "battery-up";
  version = "0.1.5";

  src = fetchzip {
    url = "https://github.com/lluz55/battery_up/releases/download/v${version}/battery-up-v${version}-x86_64-linux.tar.gz";
    hash = "sha256-PoCL682E+7f3PgEgJQpkj2N+17R7SRAv8OhWReHQWyU=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall
    install -m755 -D battery-up $out/bin/battery-up
    runHook postInstall
  '';

  meta = with lib; {
    description = "Measure notebook time running only on battery";
    homepage = "https://github.com/lluz55/battery_up";
    license = licenses.mit;
    mainProgram = "battery-up";
    platforms = platforms.linux;
  };
}
