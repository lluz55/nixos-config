{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
  libxcb,
}:

let
  version = "0.9.1";

  sources = {
    x86_64-linux = {
      url = "https://github.com/opensec-git/Pi-Bolt/releases/download/bolt-v${version}/pi-bolt-linux-x64.tar.gz";
      hash = "sha256-uOwdwtCR/U7X8R7DjZe7zO3rscg2DqmBPTgmRgDPDL4=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation rec {
  pname = "pi-bolt";
  inherit version;

  src = fetchzip {
    inherit (source) url;
    hash = source.hash;
  };

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
