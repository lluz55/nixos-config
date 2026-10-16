# minimax-code (`mcode`) — ahead do empacotamento do llm-agents.nix.
#
# Por que existe local: o upstream fixa a versão em
# `packages/minimax-code/hashes.json`, que estava em 0.6.11 enquanto o npm já
# publicava 0.6.12. Em vez de `overrideAttrs` sobre a derivação do upstream
# (abordagem que NÃO funciona aqui — o fetcher de npmDeps resolve o FOD a partir
# dos valores capturados na construção original, então continuaria buscando o
# tarball e o lockfile do 0.6.11), este arquivo reconstrói a derivação com
# versão e hashes explícitos.
#
# O `npmDepsHash` é o mesmo do 0.6.11 de propósito, e isso é correto, não
# um resíduo: os `package.json` do 0.6.11 e do 0.6.12 são idênticos exceto pelo
# campo `version` (verificado com diff), logo a árvore de dependências não mudou
# e o mesmo lockfile/`npmDepsHash` serve aos dois. Se o 0.6.13 mexer em
# dependência, este hash para de valer e o build falha com o hash esperado na
# mensagem — que é o sinal para bumpá-lo.
{
  lib,
  buildNpmPackage,
  fetchurl,
  runCommand,
  versionCheckHook,
  # Parâmetros de versão: o padrão é o que está no npm hoje.
  version ? "0.6.12",
  sourceHash ? "sha256-2PpZ26evw9BgNnwb1bSftF7UP4RmhxguT+oqGh8pMVA=",
  npmDepsHash ? "sha256-5D8XkHMNGwEcRRR2FXzrRI3gb/Bit0nWZZ0NP+x8eG8=",
  # O lockfile vem do llm-agents para não duplicar esse arquivo aqui.
  packageLock,
}:

let
  # Mesma montagem do upstream: o tarball do npm não traz package-lock.json, e o
  # fetcher de npmDeps exige um lockfile para fixar a resolução.
  srcWithLock = runCommand "minimax-code-src-with-lock" { } ''
    mkdir -p $out
    tar -xzf ${
      fetchurl {
        url = "https://registry.npmjs.org/@minimax-ai/code/-/code-${version}.tgz";
        hash = sourceHash;
      }
    } -C $out --strip-components=1
    cp ${packageLock} $out/package-lock.json
  '';
in
buildNpmPackage {
  pname = "minimax-code";
  inherit version;
  src = srcWithLock;

  inherit npmDepsHash;
  npmDepsFetcherVersion = 2;

  # root postinstall e @vscode/ripgrep batem na rede.
  npmFlags = [ "--ignore-scripts" ];
  preBuild = "npm rebuild --ignore-scripts=false better-sqlite3";
  dontNpmBuild = true;

  postInstall = ''
    find $out -path '*/better-sqlite3/build/*' ! -name better_sqlite3.node -type f -delete
  '';

  doInstallCheck = true;
  # Só `versionCheckHook`, ao contrário do upstream que também usa
  # `versionCheckHomeHook`: esse atributo foi removido do top-level do nixpkgs e
  # o `mcode --version` roda bem sem HOME temporário.
  nativeInstallCheckInputs = [versionCheckHook];

  meta = {
    description = "Open-source coding agent for your terminal, powered by MiniMax";
    homepage = "https://github.com/MiniMax-AI/minimax-code";
    changelog = "https://www.npmjs.com/package/@minimax-ai/code/v/${version}";
    license = lib.licenses.mit;
    mainProgram = "mcode";
    platforms = lib.platforms.unix;
  };
}