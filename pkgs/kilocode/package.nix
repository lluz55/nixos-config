{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
}:

let
  version = "7.4.20";

  sources = {
    x86_64-linux = {
      url = "https://registry.npmjs.org/@kilocode/cli-linux-x64/-/cli-linux-x64-${version}.tgz";
      hash = "sha256-7k5hKMHDsWyT+rlsV7OTIh9Vrs3v9fDbLGWNCmSK1DI=";
    };
    aarch64-linux = {
      url = "https://registry.npmjs.org/@kilocode/cli-linux-arm64/-/cli-linux-arm64-${version}.tgz";
      hash = "sha256-AGu78ZQpif4BIj9B4y2rJY3b7M/oUFWUoyCck3REXrs=";
    };
  };

  source = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation rec {
  pname = "kilocode";
  inherit version;

  src = fetchzip {
    inherit (source) url hash;
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

    mkdir -p $out/lib/kilocode $out/bin
    cp -r bin/* $out/lib/kilocode/

    makeWrapper $out/lib/kilocode/kilo $out/bin/kilo \
      --set-default KILO_TREE_SITTER_WASM_DIR "$out/lib/kilocode/tree-sitter"

    ln -s $out/bin/kilo $out/bin/kilocode

    runHook postInstall
  '';

  meta = with lib; {
    description = "The AI coding agent built for the terminal (Kilo CLI)";
    homepage = "https://github.com/Kilo-Org/kilocode";
    downloadPage = "https://www.npmjs.com/package/@kilocode/cli";
    license = licenses.mit;
    mainProgram = "kilo";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
