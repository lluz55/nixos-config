{ lib, stdenvNoCC, nodejs }:

stdenvNoCC.mkDerivation {
  pname = "cota-dashboard";
  version = "1.0.0";

  src = ../../../.9router/dashboard/cota;

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/cota-dashboard
    cp -r $src/index.html $src/server.js $src/package.json $out/lib/cota-dashboard/
    chmod +x $out/lib/cota-dashboard/server.js
    runHook postInstall
  '';

  meta = with lib; {
    description = "Visual quota dashboard for 9Router, served as a same-origin reverse proxy to localhost:20128.";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
