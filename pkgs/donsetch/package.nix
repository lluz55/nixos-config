{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
}:

stdenv.mkDerivation rec {
  pname = "donsetch";
  version = "3.1.0";

  src = fetchzip {
    url = "https://github.com/dondai44423/donsetch/releases/download/v${version}/donsetch-linux-x64.tar.gz";
    hash = "sha256-KmdTPBQLQg+xKOVNXmVgLhTEXHerp4YH1xMhYMgpqpU=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall
    install -m755 -D donsetch $out/bin/donsetch
    runHook postInstall
  '';

  meta = with lib; {
    description = "Web fetch, search and crawl for AI agents";
    homepage = "https://github.com/dondai44423/donsetch";
    license = licenses.agpl3Only;
    mainProgram = "donsetch";
    platforms = [ "x86_64-linux" ];
  };
}
