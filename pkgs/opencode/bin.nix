{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
}:

let
  version = "2.0.29";

  sources = {
    x86_64-linux = {
      url = "https://registry.npmjs.org/@opencode/cli-linux-x64/-/cli-linux-x64-${version}.tgz";
      hash = "sha256-6+Q2KJrmv1Et/5GE908ZQK/rZ8jw6ZLd8cPeaBd4VoY=";
    };
    aarch64-linux = {
      url = "https://registry.npmjs.org/@opencode/cli-linux-arm64/-/cli-linux-arm64-${version}.tgz";
      hash = "sha256-4asVZRzBzAmpwKOtt69ZkpLk6slFS2wXcTiR4DdT748=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "opencode-bin";
  inherit version;

  src = fetchzip {
    inherit (source) url;
    hash = source.hash;
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp bin/opencode $out/bin/opencode
    chmod +x $out/bin/opencode

    runHook postInstall
  '';

  meta = with lib; {
    description = "OpenCode 2.0 CLI binary - AI coding agent";
    homepage = "https://github.com/anomalyco/opencode";
    license = licenses.mit;
    mainProgram = "opencode";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
