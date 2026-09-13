{
  writeShellApplication,
  hermes-agent,
  curl,
}:
# Hermes Agent apontado para o 9router (gateway OpenAI-compatible local).
#
# O 9router expõe /v1 no estilo OpenAI, então o caminho suportado pelo Hermes é
# o provider "openai-api" com OPENAI_BASE_URL redirecionado — o provider lê a
# URL de OPENAI_BASE_URL (base_url_env_var no PROVIDER_REGISTRY do Hermes) e o
# `--provider` na linha de comando ganha do model.provider do config.yaml.
#
# HERMES_HOME próprio: o config/estado do Hermes "normal" (contas Nous, OAuth,
# sessões) não se mistura com o perfil que fala com o gateway.
writeShellApplication {
  name = "hermes-9router";
  runtimeInputs = [hermes-agent curl];
  text = ''
    export HERMES_HOME="''${HERMES_9ROUTER_HOME:-$HOME/.hermes-9router}"
    mkdir -p "$HERMES_HOME"

    base_url="''${HERMES_9ROUTER_BASE_URL:-http://127.0.0.1:20128/v1}"

    if ! curl -fsS -m 3 -o /dev/null "$base_url/models"; then
      echo "hermes-9router: $base_url não respondeu — o 9router está de pé? (systemctl status 9router)" >&2
      exit 1
    fi

    export OPENAI_BASE_URL="$base_url"
    # /v1/models responde sem auth, mas /v1/chat/completions exige uma das API
    # keys emitidas pelo 9router (dashboard em http://127.0.0.1:20128 → API Keys).
    if [ -z "''${NINE_ROUTER_API_KEY:-}" ]; then
      echo "hermes-9router: defina NINE_ROUTER_API_KEY com uma key emitida no dashboard do 9router (http://127.0.0.1:20128)" >&2
      exit 1
    fi
    export OPENAI_API_KEY="''${NINE_ROUTER_API_KEY}"

    # Flags antes de "$@" para que o usuário possa sobrescrever
    # (ex.: hermes-9router -m cc/claude-opus-5).
    exec hermes \
      --provider openai-api \
      --model "''${HERMES_9ROUTER_MODEL:-my-combo}" \
      "$@"
  '';

  meta = {
    description = "Hermes Agent com perfil isolado, roteando modelos pelo 9router local";
    mainProgram = "hermes-9router";
  };
}
