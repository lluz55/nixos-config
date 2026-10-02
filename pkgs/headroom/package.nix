{ writeShellApplication, uv, git, coreutils, bash, python313, stdenv }:

writeShellApplication {
  name = "headroom";
  runtimeInputs = [ uv git coreutils bash python313 ];
  text = ''
    # O NixOS nao executa os binarios pre-compilados que o uv baixa
    # (python-build-standalone e linkado contra um glibc generico), entao
    # apontamos o uv para o interpretador do nixpkgs.
    export UV_PYTHON_DOWNLOADS=never
    export UV_PYTHON="${python313}/bin/python3"
    export LD_LIBRARY_PATH="${stdenv.cc.cc.lib}/lib:''${LD_LIBRARY_PATH:-}"

    exec uvx --from "headroom-ai[all]" headroom "$@"
  '';

  meta = {
    description = "Headroom CLI runner using uvx";
    mainProgram = "headroom";
  };
}
