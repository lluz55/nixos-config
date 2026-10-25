{
  lib,
  stdenv,
  src,
  autoPatchelfHook,
  makeWrapper,
  libxcb,
}:

stdenv.mkDerivation rec {
  pname = "pi-bolt";
  version = "unstable-${builtins.substring 0 12 (builtins.hashString "sha256" (toString src))}";
  inherit src;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    libxcb
  ];

  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/pi-bolt
    cp -r * $out/lib/pi-bolt/

    makeWrapper $out/lib/pi-bolt/pi $out/bin/pi-bolt
    ln -s pi-bolt $out/bin/pibolt

    runHook postInstall
  '';

  meta = with lib; {
    description = "Ahead-of-time compiled native version of Pi coding agent";
    homepage = "https://github.com/opensec-git/Pi-Bolt";
    license = licenses.mit;
    mainProgram = "pi-bolt";
    platforms = [ "x86_64-linux" ];
  };
}
