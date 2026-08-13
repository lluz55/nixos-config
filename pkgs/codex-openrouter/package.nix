{ writeShellApplication, codex }:

writeShellApplication {
  name = "codex-openrouter";
  runtimeInputs = [ codex ];
  text = ''
    export CODEX_HOME="$HOME/.codex-openrouter"
    mkdir -p "$CODEX_HOME"

    if [ -z "''${OPENROUTER_API_KEY:-}" ]; then
      echo "codex-openrouter: defina OPENROUTER_API_KEY antes de rodar (ex: export OPENROUTER_API_KEY=sk-or-...)" >&2
      exit 1
    fi

    if [ ! -f "$CODEX_HOME/config.toml" ]; then
      cat > "$CODEX_HOME/config.toml" <<'EOF'
model_provider = "openrouter"
model = "openai/gpt-5.1"
model_reasoning_effort = "high"

[model_providers.openrouter]
name = "openrouter"
base_url = "https://openrouter.ai/api/v1"
env_key = "OPENROUTER_API_KEY"
EOF
      echo "codex-openrouter: config inicial criado em $CODEX_HOME/config.toml (edite à vontade)" >&2
    fi

    exec codex "$@"
  '';

  meta = {
    description = "Codex CLI isolado (CODEX_HOME próprio) configurado para rodar via OpenRouter";
    mainProgram = "codex-openrouter";
  };
}
