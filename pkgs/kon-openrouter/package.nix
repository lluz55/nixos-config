{ writeShellApplication, kon }:

writeShellApplication {
  name = "kon-openrouter";
  runtimeInputs = [ kon ];
  text = ''
    # Config/estado isolados para não misturar com o kon "normal"
    # (kon respeita XDG_CONFIG_HOME; ver get_config_dir() em src/kon/config.py).
    export XDG_CONFIG_HOME="''${KON_OPENROUTER_CONFIG_HOME:-$HOME/.config/kon-openrouter}"
    mkdir -p "$XDG_CONFIG_HOME"

    if [ -z "''${OPENROUTER_API_KEY:-}" ]; then
      echo "kon-openrouter: defina OPENROUTER_API_KEY antes de rodar (ex: export OPENROUTER_API_KEY=sk-or-...)" >&2
      exit 1
    fi

    # kon lê a chave de OPENAI_API_KEY em endpoints compatíveis com OpenAI.
    export OPENAI_API_KEY="$OPENROUTER_API_KEY"

    # Flags entram antes de "$@" para que o usuário possa sobrescrever
    # qualquer uma (ex.: kon-openrouter -m anthropic/claude-sonnet-5).
    exec kon \
      --provider openai \
      --base-url https://openrouter.ai/api/v1 \
      --model "''${KON_OPENROUTER_MODEL:-openai/gpt-5.1}" \
      "$@"
  '';

  meta = {
    description = "kon isolado (config própria) configurado para rodar via OpenRouter";
    mainProgram = "kon-openrouter";
  };
}
