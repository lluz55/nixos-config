{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  wrapGAppsHook3,
  atk,
  cairo,
  dbus,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  harfbuzz,
  libepoxy,
  libsecret,
  libxml2,
  pango,
  sqlite,
  systemd,
  libxkbcommon,
  libgcrypt,
  xorg,
  gsettings-desktop-schemas,
}:

stdenv.mkDerivation rec {
  pname = "bestfin";
  version = "1.0.11";

  src = fetchzip {
    url = "https://github.com/lluz55/dl_bestfin/releases/download/v${version}/bestfin-v${version}-linux-x64.tar.gz";
    hash = "sha256-+/2ntb/tq2XpGlgn1ZoNqlPaRS10SXDODjQr4nxX3Dc=";
    stripRoot = false;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    atk
    cairo
    dbus
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    libepoxy
    libsecret
    libxml2
    pango
    sqlite
    systemd
    libxkbcommon
    libgcrypt
    gsettings-desktop-schemas
    xorg.libX11
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXinerama
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/bestfin
    cp -r * $out/lib/bestfin/

    mkdir -p $out/bin
    ln -s $out/lib/bestfin/bestfin $out/bin/bestfin

    runHook postInstall
  '';

  meta = with lib; {
    description = "BestFin personal finance app";
    homepage = "https://github.com/lluz55/dl_bestfin";
    license = licenses.mit;
    mainProgram = "bestfin";
    platforms = [ "x86_64-linux" ];
  };
}
