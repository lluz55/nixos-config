{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
}:

let
  version = "1.1.21";

  sources = {
    x86_64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.21-6424454201475072/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha256-VEa7uZw8sweQaGMFx9R4OCV33XnN81Les6mnCTKBOkk=";
    };
  };

  source = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation rec {
  pname = "antigravity-cli";
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
  ];

  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/antigravity-cli
    cp -r * $out/lib/antigravity-cli/

    if [ -f "$out/lib/antigravity-cli/antigravity" ]; then
      makeWrapper $out/lib/antigravity-cli/antigravity $out/bin/agy
    elif [ -f "$out/lib/antigravity-cli/agy" ]; then
      makeWrapper $out/lib/antigravity-cli/agy $out/bin/agy
    fi

    ln -s $out/bin/agy $out/bin/antigravity

    runHook postInstall
  '';

  meta = with lib; {
    description = "Google Antigravity CLI: lightweight, terminal-based AI agent interface";
    homepage = "https://antigravity.google";
    license = licenses.unfree;
    mainProgram = "agy";
    platforms = [ "x86_64-linux" ];
  };
}
