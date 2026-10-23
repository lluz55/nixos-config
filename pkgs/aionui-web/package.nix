# AionUi WebUI — renderer estático + servidor de arquivos + auth, sem Electron.
#
# Publicada como tarball pronto no campo releases do GitHub. NÃO é empacotada
# para nixpkgs nem publicada no npm (`@aionui/web-host` e `@aionui/web-cli` são
# `private: true`), então o caminho suportado pelo upstream é baixar o asset.
#
# ## Por que 2.1.0 e não a última
#
# A partir da v2.1.54 o projeto deixou de anexar assets nas releases — a v2.2.2
# (a mais recente) tem `assets: []`, e o próprio corpo da release avisa que os
# instaladores saíram do GitHub. A v2.1.0 é a release mais nova com
# `aionui-web-<ver>-linux-x86_64.tar.gz` disponível, então é o que dá para
# instalar sem compilar o monorepo com bun.
#
# ## Versão do backend é independente
#
# Este tarball traz um `bundled-aioncore` (v0.1.9 no 2.1.0) só como fallback.
# O módulo NÃO o usa: passa `--backend-bin` apontando para o `aioncore` do
# input `aioncore` (v0.2.2, pinado na tag de release do AionCore). Testei essa
# combinação — renderer 2.1.0 falando com backend 0.2.2 — e a UI sobe, serve os
# assets e faz proxy da API corretamente.
#
# Para subir a versão do WebUI:
#   1. confira se a release chosen tem o asset de linux-x86_64
#   2. atualize o `hash` abaixo
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  zlib,
  xz,
  # Injetados pelo módulo (pkgs/aionui/module.nix) via callPackage.
  version ? "2.1.0",
  hash ? "sha256-fLd9u21Z7Fbyb+wxIxD4AQ+TYQUIzkvBhkDIQfRAgJY=",
}:
stdenv.mkDerivation {
  pname = "aionui-web";
  inherit version;

  src = fetchurl {
    url = "https://github.com/iOfficeAI/AionUi/releases/download/v${version}/aionui-web-${version}-linux-x86_64.tar.gz";
    inherit hash;
  };

  # O executável `aionui-web` é um binário Bun autocontido: só liga contra
  # glibc, sem dependência de node em runtime. Já o `bundled-aioncore` (fallback)
  # linka contra zlib/liblzma/libgcc_s do glibc genérico e sem o
  # autoPatchelfHook ele não sobe no store.
  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [zlib xz stdenv.cc.cc.lib];

  dontStrip = true;

  # O layout importa: o binário resolve `static/` e `bundled-aioncore/`
  # relativos ao próprio diretório, então mantemos os três juntos.
  #
  # O unpackPhase do nixpkgs detectou "aionui-web" como diretório raiz único e
  # JÁ removeu esse nível ("source root is aionui-web"), então os caminhos
  # abaixo são relativos à raiz do source, sem o prefixo aionui-web/.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec/aionui-web
    cp -r static bundled-aioncore package.json $out/libexec/aionui-web/
    install -Dm755 aionui-web $out/libexec/aionui-web/aionui-web
    chmod +x $out/libexec/aionui-web/bundled-aioncore/linux-x64/aioncore

    # Setamos AIONUI_STATIC_DIR explicitamente para não depender da resolução
    # relativa ao diretório do binário, e o PATH para o bundled-aioncore
    # conseguir achar suas libs.
    makeWrapper $out/libexec/aionui-web/aionui-web $out/bin/aionui-web \
      --set-default AIONUI_STATIC_DIR $out/libexec/aionui-web/static \
      --prefix PATH : ${lib.makeBinPath [stdenv.cc.cc.lib zlib xz]}

    runHook postInstall
  '';

  passthru = {
    # Caminho do backend que o WebUI deve usar (injetado pelo módulo).
    inherit version;
  };

  meta = {
    description = "AionUi WebUI — renderer web estático + host HTTP, sem Electron";
    homepage = "https://github.com/iOfficeAI/AionUi";
    license = lib.licenses.asl20;
    mainProgram = "aionui-web";
    platforms = lib.platforms.linux;
  };
}
