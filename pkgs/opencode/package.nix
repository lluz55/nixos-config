{ writeShellApplication, opencode }:

writeShellApplication {
  name = "opencode";
  runtimeInputs = [ opencode ];
  text = ''
    export OPENCODE_HOME="''${OPENCODE_HOME:-$HOME/.opencode}"
    mkdir -p "$OPENCODE_HOME"

    if [ -z "''${OPENCODE_API_KEY:-}" ]; then
      if [ -f /run/secrets/opencode/api_key ]; then
        OPENCODE_API_KEY="$(cat /run/secrets/opencode/api_key)"
        export OPENCODE_API_KEY
      else
        echo "opencode: defina OPENCODE_API_KEY ou configure o segredo sops" >&2
        exit 1
      fi
    fi

    exec opencode "$@"
  '';

  meta = {
    description = "OpenCode CLI com chave via segredo sops";
    mainProgram = "opencode";
  };
}
