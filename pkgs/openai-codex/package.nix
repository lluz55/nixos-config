{
  lib,
  stdenv,
  fetchzip,
  nodejs,
  makeWrapper,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "openai-codex";
  version = "0.139.0";

  src = fetchzip {
    url = "https://registry.npmjs.org/@openai/codex/-/codex-${finalAttrs.version}.tgz";
    hash = "sha256-6l/8WGeWZ0+UkdA0hpRpQKlKeIxGVNzh/X2ihQye1NE=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/openai-codex $out/bin
    cp -r . $out/lib/openai-codex/
    makeWrapper ${nodejs}/bin/node $out/bin/codex \
      --add-flags "$out/lib/openai-codex/bin/codex.js" \
      --set DISABLE_AUTOUPDATER 1
    runHook postInstall
  '';

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    downloadPage = "https://www.npmjs.com/package/@openai/codex";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = lib.platforms.unix;
  };
})
