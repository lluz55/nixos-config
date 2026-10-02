{
  lib,
  buildNpmPackage,
  nodejs_24,
  makeWrapper,
  autoPatchelfHook,
  stdenv,
  procps,
}:

buildNpmPackage (finalAttrs: {
  pname = "omniroute";
  version = "3.8.50";

  # The upstream flake currently exports only a development shell.  This small
  # wrapper pins the published npm artifact and its complete dependency tree.
  src = lib.cleanSource ./.;
  npmDepsHash = "sha256-W88zBR9EgvVhjKbivOYtM4Kjq+2eR4rWEm0B4mWjXlk=";
  nodejs = nodejs_24;

  npmFlags = [
    "--include=optional"
    "--legacy-peer-deps"
    "--ignore-scripts"
  ];
  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ] ++ lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;
  autoPatchelfIgnoreMissingDeps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/omniroute
    cp -a package.json node_modules $out/lib/omniroute/

    makeWrapper ${lib.getExe nodejs_24} $out/bin/omniroute \
      --add-flags $out/lib/omniroute/node_modules/omniroute/bin/omniroute.mjs \
      --suffix PATH : ${lib.makeBinPath [ procps ]}

    runHook postInstall
  '';

  meta = {
    description = "Unified AI gateway and routing dashboard";
    homepage = "https://github.com/diegosouzapw/OmniRoute";
    license = lib.licenses.mit;
    mainProgram = "omniroute";
    platforms = lib.platforms.linux;
  };
})
