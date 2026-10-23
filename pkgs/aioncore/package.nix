# Backend (Rust) do AionUi — https://github.com/iOfficeAI/AionCore
#
# O upstream publica binários pré-compilados para linux no campo releases, um
# por par rustc/target. Pegamos o `x86_64-unknown-linux-gnu` direto do release
# em vez de compilar os ~30 crates do workspace com cargo: sem toolchain Rust
# no build, sem `cargoHash`, e o resultado é bit-idêntico ao que o upstream
# testa.
#
# A tag de release fica num input separado do flake (`inputs.aioncore`), então
# `nix flake update aioncore` mexe só aqui e não arrasta o nixpkgs junto.
# Quem passa a versão é o módulo (pkgs/aionui/module.nix): ele lê
# `workspace.package.version` do Cargo.toml do input pinado e repassa via
# callPackage, garantindo que a URL do asset e o input nunca divirjam. O default
# abaixo só existe para este arquivo ser buildável isolado
# (`nix build -f pkgs/aioncore/package.nix`), e precisa bater com a tag.
#
# Para subir de versão:
#   1. edite a tag em flake.nix (inputs.aioncore.url)
#   2. nix flake update aioncore
#   3. atualize o `hash` aqui e no módulo com o comando documentado lá
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  zlib,
  xz,
  # Injetados pelo módulo (pkgs/aionui/module.nix) via callPackage. Não vêm do
  # nixpkgs porque dependem do input `aioncore` e do hash do asset de release.
  version ? "0.1.9",
  hash ? "sha256-FXJ6Qy7Ck1kEZ1F9I5nqPbKx+PIAvzUaVJSUGW58+sg=",
}: let
  target = "x86_64-unknown-linux-gnu";
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "aioncore";
    inherit version;

    # Não é um repo git: é o tarball de release.
    src = fetchurl {
      url = "https://github.com/iOfficeAI/AionCore/releases/download/v${version}/aioncore-v${version}-${target}.tar.gz";
      inherit hash;
    };

    # O binário vem linkado contra zlib, liblzma e libgcc_s do toolchain glibc
    # genérico. Sem o autoPatchelfHook os .so apontam para caminhos que não
    # existem no store e o serviço morre no primeiro start systemd. Não usamos
    # autoPatchelfIgnoreMissingDeps: melhor resolver as libs de verdade do que
    # silenciar a dependência que faltar.
    nativeBuildInputs = [autoPatchelfHook];
    buildInputs = [
      zlib
      xz
      stdenv.cc.cc.lib
    ];

    # O asset de release é um tarball de arquivo único (só `aioncore` na raiz),
    # sem diretório de nível superior. O unpackPhase genérico do nixpkgs aborta
    # com "unpacker appears to have produced no directories", e `dontUnpack`
    # impede registrar um unpackPhase custom (o stdenv só registra o hook quando
    # dontUnpack é falso). Então descompactamos aqui, dentro do installPhase.
    dontUnpack = true;

    dontStrip = true;

    installPhase = ''
      runHook preInstall

      mkdir -p source-dir
      tar -xzf "$src" -C source-dir
      install -Dm755 source-dir/aioncore $out/bin/aioncore

      runHook postInstall
    '';

    # Sem checagem automática: `doctor` sonda cada CLI do PATH e o PATH do
    # sandbox de build é mínimo, então no build ele reportaria tudo como missing
    # e o "sucesso" não diria nada. A validação real é rodar `doctor` no host,
    # que é o que o passthru abaixo facilita.
    doCheck = false;

    passthru = {
      # Executa a tabela de detecção de agentes. Útil para confirmar quais dos
      # seus CLIs o aioncore enxerga, já que o ambiente do serviço tem PATH
      # próprio (limitado ao do systemd, não ao do seu shell).
      doctor = ''
        exec ${finalAttrs.finalPackage}/bin/aioncore doctor "$@"
      '';
      inherit target;
    };

    meta = {
      description = "AionUi backend server (Rust) — ACP control plane para agentes CLI locais";
      homepage = "https://github.com/iOfficeAI/AionCore";
      license = lib.licenses.asl20;
      mainProgram = "aioncore";
      platforms = lib.platforms.unix;
    };
  })
