{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.7.1";
  sources = {
    x86_64-linux = {
      url = "https://github.com/Agent-Field/CodeAF/releases/download/v${version}/codeaf-linux-amd64";
      hash = "sha256-hdiFk5qGv1NciYpjx1zU2sShF0k1f2Bm/hzpMDJLyug=";
    };
  };
  source = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "codeaf";
  inherit version;

  src = fetchurl {
    inherit (source) url hash;
  };

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp $src $out/bin/codeaf
    chmod +x $out/bin/codeaf
    runHook postInstall
  '';

  meta = with lib; {
    description = "CodeAF: agentic coding harness and software factory by AgentField";
    homepage = "https://github.com/Agent-Field/CodeAF";
    license = licenses.asl20;
    mainProgram = "codeaf";
    platforms = [ "x86_64-linux" ];
  };
}
