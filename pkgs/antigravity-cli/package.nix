{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
}:

let
  # URL e sha512 extraídos do manifesto oficial do auto-updater:
  # https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_amd64.json
  # O sha512 publicado no manifesto confere com o sha512 do tarball.
  # O `hash` abaixo é o hash NAR do resultado do `fetchzip` — que desempacota
  # diferente do `nix-prefetch-url --unpack` (este usa tar), então não dá pra
  # reaproveitar o hash de `nix-prefetch-url`.
  version = "1.2.15";

  sources = {
    x86_64-linux = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.15-5434575321694208/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha256-qm1/aXpYsvy/GvyLWZ4nIL8ijZ1iHWI8MINUtQSQfVE=";
    };
  };

  source = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation rec {
  pname = "antigravity-cli";
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

    mkdir -p $out/bin $out/lib/antigravity-cli
    cp -r * $out/lib/antigravity-cli/

    if [ -f "$out/lib/antigravity-cli/antigravity" ]; then
      makeWrapper $out/lib/antigravity-cli/antigravity $out/bin/agy
    elif [ -f "$out/lib/antigravity-cli/agy" ]; then
      makeWrapper $out/lib/antigravity-cli/agy $out/bin/agy
    fi

    ln -s $out/bin/agy $out/bin/antigravity

    runHook postInstall
  '';

  meta = with lib; {
    description = "Google Antigravity CLI: lightweight, terminal-based AI agent interface";
    homepage = "https://antigravity.google";
    license = licenses.unfree;
    mainProgram = "agy";
    platforms = [ "x86_64-linux" ];
  };
}
