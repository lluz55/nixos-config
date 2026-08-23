{
  lib,
  buildNpmPackage,
  nodejs_22,
  python3,
  makeWrapper,
  autoPatchelfHook,
  stdenv,
  git,
  ripgrep,
}:

# O tarball publicado do @deepseek-ai/dsh nao traz lockfile, entao o
# package.json/package-lock.json deste diretorio sao um wrapper gerado com
# `npm install --package-lock-only` que fixa a arvore de dependencias.
# Para atualizar: mude a versao em package.json, rode o comando acima e
# atualize npmDepsHash.
buildNpmPackage (finalAttrs: {
  pname = "dsh";
  version = "0.1.0-rc.7";

  src = lib.cleanSource ./.;

  npmDepsHash = "sha256-Rk8YhH5B2NHs8bFTlBRnApn+8O0LcvVai+Af09ElrXA=";

  nodejs = nodejs_22;

  # node-pty e koffi trazem .node pre-compilados que precisam ser religados
  # contra as libs do nixpkgs.
  nativeBuildInputs = [ makeWrapper python3 ]
    ++ lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;

  buildInputs = [ stdenv.cc.cc.lib ];
  autoPatchelfIgnoreMissingDeps = true;

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/dsh
    cp -a package.json node_modules $out/lib/dsh/

    makeWrapper ${lib.getExe nodejs_22} $out/bin/dsh \
      --add-flags $out/lib/dsh/node_modules/@deepseek-ai/dsh/lib/bin.js \
      --suffix PATH : ${lib.makeBinPath [ git ripgrep ]}

    runHook postInstall
  '';

  meta = {
    description = "DeepSeek Harness CLI (dsh)";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    license = lib.licenses.mit;
    mainProgram = "dsh";
    platforms = lib.platforms.unix;
  };
})
