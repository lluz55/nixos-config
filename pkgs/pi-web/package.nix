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

# O tarball publicado do @jmfederico/pi-web não traz lockfile, então o
# package.json/package-lock.json deste diretório são um wrapper gerado com
# `npm install --package-lock-only` que fixa a árvore de dependências.
# Para atualizar: mude a versão em package.json, rode o comando acima e
# atualize npmDepsHash.
#
# node-pty é fixado em 1.2.0-beta.15 via override: a 1.1.0 (range do pi-web)
# não publica prebuilds linux, o que forçaria node-gyp rebuild (falha no
# Nix sem os headers/caches de npm esperados). A 1.2.0-beta.15 traz
# prebuilds/linux-x64/pty.node, mesmo padrão usado no dsh.
buildNpmPackage (finalAttrs: {
  pname = "pi-web";
  version = "1.202609.0";

  src = lib.cleanSource ./.;

  npmDepsHash = "sha256-RupP0TABHX0ymRj6dX+ObeL17T1fmc6vYyigoe4Cp+o=";

  # v2 fetcher usa layout de cache que resolve pacotes só-aninhados
  # (ex.: @earendil-works/pi-tui) sem dar ENOTCACHED em modo offline.
  npmDepsFetcherVersion = 2;

  nodejs = nodejs_22;

  # npm ci roda em modo offline (only-if-cached) e, sem isto, pacotes só
  # presentes como entrada aninhada no lockfile (ex.: pi-tui) dão ENOTCACHED.
  # --prefer-offline faz o npm usar o cache antes de bater na rede.
  npmInstallFlags = [ "--prefer-offline" ];

  # node-pty traz .node pré-compilado que precisa ser religado contra as
  # libs do nixpkgs.
  nativeBuildInputs = [ makeWrapper python3 ]
    ++ lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;

  buildInputs = [ stdenv.cc.cc.lib ];
  autoPatchelfIgnoreMissingDeps = true;

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/pi-web
    cp -a package.json node_modules $out/lib/pi-web/

    makeWrapper ${lib.getExe nodejs_22} $out/bin/pi-web \
      --add-flags "$out/lib/pi-web/node_modules/@jmfederico/pi-web/dist/cli.js" \
      --suffix PATH : ${lib.makeBinPath [ git ripgrep ]}

    makeWrapper ${lib.getExe nodejs_22} $out/bin/pi-web-server \
      --add-flags "$out/lib/pi-web/node_modules/@jmfederico/pi-web/dist/server/index.js" \
      --suffix PATH : ${lib.makeBinPath [ git ripgrep ]}

    makeWrapper ${lib.getExe nodejs_22} $out/bin/pi-web-sessiond \
      --add-flags "$out/lib/pi-web/node_modules/@jmfederico/pi-web/dist/server/sessiond.js" \
      --suffix PATH : ${lib.makeBinPath [ git ripgrep ]}

    runHook postInstall
  '';

  meta = {
    description = "Web UI for persistent Pi Coding Agent sessions in real workspaces";
    homepage = "https://pi-web.dev/";
    license = lib.licenses.mit;
    mainProgram = "pi-web";
    platforms = lib.platforms.unix;
  };
})
