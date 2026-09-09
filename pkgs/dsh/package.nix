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
  version = "0.1.3-alpha.2";

  src = lib.cleanSource ./.;

  npmDepsHash = "sha256-zeU4NWY5J0Pe0Gadx6q85t0T/G3ttU5Ei1/JBjCzyXU=";

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

    # --expose-internals: o bundle @deepseek-ai/cordis-plugin-hmr (parte do
    # perfil "web") exige acesso às internals do Node para o watcher de HMR;
    # sem essa flag o boot falha com "--expose-internals is required for HMR
    # service" (ou, em builds mais antigas do dsh, crasha com SIGSEGV direto
    # dentro do V8 ao tentar tocar essas internals sem a flag). Ver
    # https://github.com/deepseek-ai/deepseek-harness/discussions/1313.
    makeWrapper ${lib.getExe nodejs_22} $out/bin/dsh \
      --add-flags "--expose-internals $out/lib/dsh/node_modules/@deepseek-ai/dsh/lib/bin.js" \
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
