{
  lib,
  buildNpmPackage,
  nodejs_22,
  makeWrapper,
  autoPatchelfHook,
  stdenv,
  procps,
}:

# O pacote "9router" no npm não traz lockfile (é publicado só com o
# cli.js + deps diretas), então o package.json/package-lock.json deste
# diretório são um wrapper gerado com `npm install --package-lock-only`
# que fixa a árvore de dependências.
#
# Para atualizar para uma nova versão do 9router:
#   1. `npm view 9router version` para conferir a última versão publicada.
#   2. Editar o campo "9router" em pkgs/9router/package.json para a nova versão.
#   3. Rodar, dentro de pkgs/9router/:
#        rm -f package-lock.json && npm install --package-lock-only
#      para regenerar o lockfile.
#   4. Atualizar npmDepsHash abaixo — o build falha e imprime o hash correto
#      (defina npmDepsHash = "" temporariamente, rode o build, copie o hash
#      "got:" do erro).
#   5. `nix build .#9router` (ou `nixos-rebuild switch --flake .#<host>`) para validar.
#
# `nix flake update` sozinho NÃO atualiza esta versão: ele só atualiza os
# inputs do flake.nix (nixpkgs, home-manager, etc). O 9router é buscado do
# registro npm no momento do build (via npmDepsHash fixo), não de um input
# do flake, então o bump de versão acima é sempre manual.
buildNpmPackage (finalAttrs: {
  pname = "9router";
  version = "0.5.69";

  src = lib.cleanSource ./.;

  npmDepsHash = "sha256-mgJM/Rq89lpUhhyNIbxQadIpw6o1IduNDkoWk3CJqu8=";

  nodejs = nodejs_22;

  nativeBuildInputs = [ makeWrapper ]
    ++ lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;

  autoPatchelfIgnoreMissingDeps = true;

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/9router
    cp -a package.json node_modules $out/lib/9router/

    makeWrapper ${lib.getExe nodejs_22} $out/bin/9router \
      --add-flags $out/lib/9router/node_modules/9router/cli.js \
      --suffix PATH : ${lib.makeBinPath [ procps ]}

    runHook postInstall
  '';

  meta = {
    description = "9Router AI proxy gateway CLI";
    homepage = "https://github.com/decolua/9router";
    license = lib.licenses.mit;
    mainProgram = "9router";
    platforms = lib.platforms.unix;
  };
})
