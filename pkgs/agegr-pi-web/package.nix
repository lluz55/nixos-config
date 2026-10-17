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

# Wrapper Nix do @agegr/pi-web (npm @agegr/pi-web).
#
# O pacote publicado no npm vem SEM lockfile próprio, então o
# package.json/package-lock.json deste diretório são um wrapper gerado com
# `npm install --package-lock-only` que fixa a árvore de dependências.
# Para atualizar:
#   1. `npm view @agegr/pi-web version` para conferir a última versão.
#   2. Editar o campo "@agegr/pi-web" em pkgs/agegr-pi-web/package.json.
#   3. Dentro de pkgs/agegr-pi-web/, rodar:
#        rm -f package-lock.json && npm install --package-lock-only
#      para regenerar o lockfile.
#   4. Atualizar npmDepsHash abaixo — defina lib.fakeHash, rode o build, o
#      Nix imprime o hash correto no erro "hash mismatch" e você copia
#      desse output.
#   5. Validar com `nix build .#agegr-pi-web` (ou `nixos-rebuild switch
#      --flake .#<host>`).
#
# `nix flake update` sozinho NÃO atualiza esta versão: o @agegr/pi-web é
# buscado do npm registry no build (via npmDepsHash fixo), não de um input
# do flake. Bump manual acima.
#
# Diferente de @jmfederico/pi-web (pkgs/pi-web), este pacote expõe UM
# binário só (`pi-web`, que wrappa `next start` em vez de separar sessiond
# + web-server) e o tarball publicado já traz o build de produção em
# `.next/`, então `dontNpmBuild = true` (sem `npm run build` no build).
buildNpmPackage (finalAttrs: {
  pname = "agegr-pi-web";
  version = "0.11.0";

  src = lib.cleanSource ./.;

  npmDepsHash = "sha256-AhGOpYxhe73Qse6Vc2BswON+Xr9WpDgPB1E+4uLtCUU=";

  # v2 fetcher — mesma justificativa dos outros wrappers do repo:
  # resolve pacotes referenciados só-aninhados sem ENOTCACHED em offline.
  npmDepsFetcherVersion = 2;
  nodejs = nodejs_22;

  nativeBuildInputs = [ makeWrapper python3 ]
    ++ lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;
  buildInputs = [ stdenv.cc.cc.lib ];
  autoPatchelfIgnoreMissingDeps = true;

  # O tarball publicado já vem com .next/ (Next.js production build).
  dontNpmBuild = true;

  # node-pty 1.2.0-beta.15 já é o que o upstream fixa (mesma versão do
  # pkgs/pi-web). O postinstall (prepare-terminal.js) só ajusta bits em
  # macOS; no Linux é no-op e não precisamos rodar aqui — o makeWrapper
  # abaixo é suficiente.
  dontNpmInstall = false;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/agegr-pi-web
    cp -a package.json node_modules $out/lib/agegr-pi-web/

    # bin/pi-web.js usa `process.execPath` (via spawn) para chamar o next
    # CLI como child. makeWrapper garante que o node do nixpkgs (com
    # versão compatível com `engines.node >=22.19.0`) esteja no PATH.
    makeWrapper ${lib.getExe nodejs_22} $out/bin/pi-web \
      --add-flags "$out/lib/agegr-pi-web/node_modules/@agegr/pi-web/bin/pi-web.js" \
      --suffix PATH : ${lib.makeBinPath [ git ripgrep ]}

    runHook postInstall
  '';

  meta = {
    description = "Web UI for the pi coding agent (@agegr/pi-web)";
    homepage = "https://github.com/agegr/pi-web";
    license = lib.licenses.mit;
    mainProgram = "pi-web";
    platforms = lib.platforms.unix;
  };
})