{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
}:

let
  version = "1.6.0";

  sources = {
    x86_64-linux = {
      url = "https://registry.npmjs.org/@colbymchenry/codegraph-linux-x64/-/codegraph-linux-x64-${version}.tgz";
      hash = "sha256-phW0IDYOu6d3rVIS7es8YUN3SSX9OUuJmfeNecuGxOw=";
    };
    aarch64-linux = {
      url = "https://registry.npmjs.org/@colbymchenry/codegraph-linux-arm64/-/codegraph-linux-arm64-${version}.tgz";
      hash = lib.fakeHash;
    };
  };

  source = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "codegraph";
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

    mkdir -p $out/lib/codegraph $out/bin
    cp -r . $out/lib/codegraph/

    makeWrapper $out/lib/codegraph/bin/codegraph $out/bin/codegraph

    runHook postInstall
  '';

  meta = with lib; {
    description = "Local-first code intelligence for AI agents (MCP)";
    homepage = "https://github.com/colbymchenry/codegraph";
    downloadPage = "https://www.npmjs.com/package/@colbymchenry/codegraph";
    license = licenses.mit;
    mainProgram = "codegraph";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
