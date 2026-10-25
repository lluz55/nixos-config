{
  lib,
  stdenv,
  src,
}:

stdenv.mkDerivation {
  pname = "codeaf";
  version = "unstable-${builtins.substring 0 12 (builtins.hashString "sha256" (toString src))}";
  inherit src;

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
