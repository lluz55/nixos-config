{ osConfig, ... }:
{
  programs.pi-coding-agent = {
    enable = true;
    # Já instalado via environment.systemPackages em cada host.
    package = null;

    models.providers.opencode = {
      baseUrl = "https://opencode.ai/zen/v1";
      api = "openai-completions";
      # "!<cmd>" faz o pi rodar o comando e usar o stdout como a key, em
      # vez de gravá-la em texto puro no models.json. O caminho vem do
      # segredo sops "opencode/api_key" (ver hosts/configuration.nix),
      # decifrado em /run/secrets/opencode/api_key com dono lluz.
      apiKey = "!cat ${osConfig.sops.secrets."opencode/api_key".path}";
    };
  };
}
