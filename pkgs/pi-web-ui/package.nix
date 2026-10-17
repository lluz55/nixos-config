{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
  python3,
  makeWrapper,
  autoPatchelfHook,
  stdenv,
  git,
  ripgrep,
  bash,
  coreutils,
}:

buildNpmPackage (finalAttrs: {
  pname = "pi-web-ui";
  version = "0.1.0-unstable-2026-10-10";

  src = fetchFromGitHub {
    owner = "valtterimelkko";
    repo = "pi-web-ui";
    rev = "3ee38745e7cca016143b7e53b0853d5a5eff0258";
    hash = "sha256-BljFGLeHwRXa8QnVp6JypCSk3Y1kbMZGvdBYvUMBziA=";
  };

  # Upstream's workspace lock omits the registry metadata for the two nested
  # zod copies. npm accepts that, but Nix's offline cache builder correctly
  # refuses entries that cannot be fetched reproducibly.
  postPatch = ''
    ${lib.getExe nodejs_22} - <<'JS'
    const fs = require('fs');
    const path = 'package-lock.json';
    const lock = JSON.parse(fs.readFileSync(path, 'utf8'));
    const metadata = {
      'server/node_modules/zod': 'sha512-gzUt/qt81nXsFGKIFcC3YnfEAx5NkunCfnDlvuBSSFS02bcXu4Lmea0AFIUwbLWxWPx3d9p8S5QoaujKcNQxcQ==',
      'shared/node_modules/zod': 'sha512-gzUt/qt81nXsFGKIFcC3YnfEAx5NkunCfnDlvuBSSFS02bcXu4Lmea0AFIUwbLWxWPx3d9p8S5QoaujKcNQxcQ==',
      'node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/chord': 'sha512-BIfWfrByM0pKq6tfKYXuwx0ed2CvaqIM3EDA7Dps+fP+d3CiPWdlHi1cDsJC05llqKJoRz5//G0hz0yQwwjISQ==',
      'node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-agent-core': 'sha512-bHFONjtEBDqiV+g1DmmtkSlfAaqHELr+XO+6I5Nah4gswwZrLJO4yZB/JjsnlI4AKWTayBLfgS6DCbeBBz9e2Q==',
      'node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-ai': 'sha512-3/W1vdDaVtpeMd23ElvJC12HLA5yS/BGqqcXF+0SK082dN7cbgNcCwguTBRBC258Ke8SzSvUW1B75iAf8w8IxA==',
      'node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-codemode': 'sha512-LPpFI4+T9NzDnhBDs15izWAolaoM8xnwqdziRd6Zx8BQeoEPvzefD2vMMzSyF0rOtq34TfQqkZ0ki16f6cGdMg==',
      'node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-mcp': 'sha512-rYra0aF5iPmJd+fsB+VBuqxWNABGJ3Iiyhg0CqIc/91ta2n7IvQmCp0Cac/YkUTNnvRsVZnjgAiBkRi6+ouWuw==',
      'node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-telemetry': 'sha512-WjNBj5TYIiPZFQEz2WlULcDwPLaKwIlmsKjVeYM+LJSbnSp38kWsHUJysIDGnu23IcLbKoPtywsvYfUJCeZePA==',
      'node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui': 'sha512-JsT7kXnpZA2YOtQu6RyriyxEO0eJIzPyfiH09bH+OLN5+s18HYkwaUD/tBkjhnSfMu6/50CQPRYJagzSP6HdPw=='
    };
    for (const [key, integrity] of Object.entries(metadata)) {
      const entry = lock.packages[key];
      if (!entry) throw new Error(`missing expected lock entry: ''${key}`);
      if (key.endsWith('/zod')) entry.resolved = 'https://registry.npmjs.org/zod/-/zod-3.25.76.tgz';
      entry.integrity = integrity;
    }
    fs.writeFileSync(path, JSON.stringify(lock, null, 2) + '\\n');
    JS
  '';

  npmDepsHash = lib.fakeHash;
  npmDepsFetcherVersion = 2;
  nodejs = nodejs_22;
  npmInstallFlags = [ "--include=dev" "--prefer-offline" ];

  nativeBuildInputs = [ makeWrapper python3 ]
    ++ lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;
  buildInputs = [ stdenv.cc.cc.lib ];
  autoPatchelfIgnoreMissingDeps = true;

  npmBuildScript = "build";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/pi-web-ui $out/bin
    cp -a \
      package.json \
      node_modules \
      server/dist \
      server/package.json \
      client/dist \
      client/package.json \
      shared/dist \
      shared/package.json \
      packages \
      $out/lib/pi-web-ui/

    makeWrapper ${lib.getExe nodejs_22} $out/bin/pi-web-ui \
      --add-flags "$out/lib/pi-web-ui/server/dist/index.js" \
      --chdir "$out/lib/pi-web-ui" \
      --suffix PATH : ${lib.makeBinPath [ git ripgrep bash coreutils ]}

    runHook postInstall
  '';

  meta = {
    description = "Self-hosted multi-runtime web UI for coding agents";
    homepage = "https://github.com/valtterimelkko/pi-web-ui";
    license = lib.licenses.mit;
    mainProgram = "pi-web-ui";
    platforms = lib.platforms.linux;
  };
})
