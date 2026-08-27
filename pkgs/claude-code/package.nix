{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
}:

let
  version = "2.1.246";

  sources = {
    x86_64-linux = {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-${version}.tgz";
      hash = "sha256-cVwIx+nm7Ul+XrgpLUAdLm0oXptlLAjuJD2oltNW41c=";
    };
    aarch64-linux = {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-arm64/-/claude-code-linux-arm64-${version}.tgz";
      hash = lib.fakeHash;
    };
  };

  source = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation rec {
  pname = "claude-code";
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

    mkdir -p $out/bin $out/lib/claude-code
    cp -r * $out/lib/claude-code/

    if [ -f "$out/lib/claude-code/claude" ]; then
      makeWrapper $out/lib/claude-code/claude $out/bin/claude
    elif [ -f "$out/lib/claude-code/bin/claude" ]; then
      makeWrapper $out/lib/claude-code/bin/claude $out/bin/claude
    fi

    ln -s $out/bin/claude $out/bin/claude-code

    runHook postInstall
  '';

  meta = with lib; {
    description = "Claude Code: An agentic coding tool that lives in your terminal";
    homepage = "https://docs.anthropic.com/en/docs/claude-code/overview";
    downloadPage = "https://www.npmjs.com/package/@anthropic-ai/claude-code";
    license = licenses.unfree;
    mainProgram = "claude";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
