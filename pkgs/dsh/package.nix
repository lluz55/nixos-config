{
  lib,
  buildNpmPackage,
  nodejs_22,
  python3,
  makeWrapper,
  stdenv,
  git,
  ripgrep,
}:

# O tarball publicado do @deepseek-ai/dsh nao traz lockfile, entao o
# package.json/package-lock.json deste diretorio sao um wrapper gerado com
# `npm install --package-lock-only` que fixa a arvore de dependencias.
# Para atualizar: mude a versao em package.json, rode o comando acima e
# atualize npmDepsHash.
buildNpmPackage (finalAttrs: {
  pname = "dsh";
  version = "0.2.0-rc.2";

  src = lib.cleanSource ./.;

  npmDepsHash = "sha256-Cz6dKuqOWluqAwpFaOlQAYH4/vEBQOIdSrj4JeVe2tk=";

  nodejs = nodejs_22;

  # Os .node pre-compilados (node-pty, koffi, sharp) carregam bem SEM religar:
  # todas as NEEDED de sistema (libstdc++/libc/...) já vêm carregadas pelo
  # próprio node, e o sharp.node acha o libvips vendored pelo RPATH $ORIGIN
  # pristine. Já o autoPatchelfHook QUEBRA o build aqui: o
  # libvips-cpp.so.8.18.6 do @img/sharp-libvips-linux-x64 usa um layout ELF
  # empacotado (código DT_INIT dentro da área de headers) que o patchelf não
  # entende — antes corrompia os bytes do DT_INIT (SIGSEGV com SEGV_ACCERR em
  # base+0x25c no dlopen: crash-loop do `dsh web`, que importa sharp via
  # dsh-attachment-local); no patchelf atual, falha com erro e reprova o
  # build. Por isso o hook fica desligado; o smoke test no postFixup reprova
  # o build em qualquer regressão de módulo nativo.
  nativeBuildInputs = [ makeWrapper python3 ];

  buildInputs = [ stdenv.cc.cc.lib ];
  dontAutoPatchelf = true;

  dontNpmBuild = true;

  # Com dontAutoPatchelf, nada encosta nos binários: só o smoke test abaixo.
  postFixup = ''

    # Smoke test anti-regressão: .node de linux precisa carregar (OK);
    # prebuilds de outra plataforma (win32/darwin/musl/arm64) podem SKIP com
    # erro JS; crash com signal ou falha inesperada reprova o build.
    echo "dsh: smoke-testing native modules..."
    smokeFail=0
    while IFS= read -r mod; do
      if modOut=$(${lib.getExe nodejs_22} --expose-internals -e "try { process.dlopen(module, \"$mod\"); console.log('OK'); } catch (e) { console.log('ERR:' + e.code); }"); then
        case "$modOut" in
          OK) echo "OK   $mod" ;;
          *)
            if printf '%s' "$mod" | grep -qiE 'musl|darwin|win32|arm64|aarch64'; then
              echo "SKIP $mod ($modOut)"
            else
              echo "FAIL $mod ($modOut)" >&2; smokeFail=1
            fi
            ;;
        esac
      else
        echo "CRASH $mod" >&2; smokeFail=1
      fi
    done < <(find "$out/lib/dsh/node_modules" -name '*.node')
    if [ "$smokeFail" -ne 0 ]; then echo "dsh: native module smoke test FAILED" >&2; exit 1; fi
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/dsh
    cp -a package.json node_modules $out/lib/dsh/

    # O frontend upstream desabilita a persistência de Settings sempre que a
    # URL visível do navegador não é loopback. Aqui o acesso remoto passa pelo
    # dl_conn autenticado, que encaminha Host/Origin como 127.0.0.1; portanto o
    # Host já aplica sua cerca de segurança, embora o browser esteja em /dsh
    # num hostname público. Sem este ajuste, Configurações > Modelos falha com
    # "settings are unavailable in this browser" antes mesmo de chamar o RPC.
    settingsClient="$out/lib/dsh/node_modules/@deepseek-ai/dsh-client-ui-settings/lib/client.js"
    substituteInPlace "$settingsClient" \
      --replace-fail 'const persistence = ctx.remote.$host.isLoopback ? "host" : "memory";' \
                     'const persistence = "host";'

    # Patch node-addon-require-builtin para fallback em require() nativo:
    # No NixOS, o nodejs_22 é compilado com flags que alteram o layout de código
    # do getter V8 x64 sysv, fazendo a probe C++ do addon nativo falhar com
    # "Unsupported/no-getter". Como o makeWrapper roda com --expose-internals,
    # o require() nativo do Node consegue carregar os módulos internos sem falhas.
    if [ -f "$out/lib/dsh/node_modules/node-addon-require-builtin/lib/index.js" ]; then
      chmod +w $out/lib/dsh/node_modules/node-addon-require-builtin/lib/index.js
      cat << 'EOF' > $out/lib/dsh/node_modules/node-addon-require-builtin/lib/index.js
"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireBuiltin = requireBuiltin;
exports.isAllowedInternalId = isAllowedInternalId;
exports.getBindingInfo = getBindingInfo;
const node_path_1 = __importDefault(require("node:path"));
const { createEntryApi } = require('node-addon-native-custom-loader');
let api;
try {
    api = createEntryApi(node_path_1.default.resolve(__dirname, '..'));
} catch (_) {}

function requireBuiltin(moduleId) {
    if (api) {
        try {
            return api.requireBuiltin(moduleId);
        } catch (_) {}
    }
    return require(moduleId);
}
function isAllowedInternalId(moduleId) {
    if (api) {
        try {
            return api.isAllowedInternalId(moduleId);
        } catch (_) {}
    }
    return true;
}
function getBindingInfo() {
    if (api) {
        try {
            return api.getBindingInfo();
        } catch (_) {}
    }
    return { mode: "fallback", product: "require-builtin" };
}
exports.default = {
    requireBuiltin,
    isAllowedInternalId,
    getBindingInfo,
};
EOF
    fi

    # --expose-internals: o bundle @deepseek-ai/cordis-plugin-hmr (parte do
    # perfil "web") exige acesso às internals do Node para o watcher de HMR;
    # sem essa flag o boot falha com "--expose-internals is required for HMR
    # service" (ou, em builds mais antigas do dsh, crasha com SIGSEGV direto
    # dentro do V8 ao tentar tocar essas internals sem a flag). Ver
    # https://github.com/deepseek-ai/deepseek-harness/discussions/1313.
    makeWrapper ${lib.getExe nodejs_22} $out/bin/dsh \
      --add-flags "--expose-internals $out/lib/dsh/node_modules/@deepseek-ai/dsh/lib/bin.js" \
      --suffix PATH : ${lib.makeBinPath [ git ripgrep ]}

    runHook postInstall
  '';

  meta = {
    description = "DeepSeek Harness CLI (dsh)";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    license = lib.licenses.mit;
    mainProgram = "dsh";
    platforms = lib.platforms.unix;
  };
})
