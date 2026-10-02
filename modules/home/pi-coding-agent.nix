{ inputs, pkgs, ... }:
{
  # O módulo é importado pelo desktopProfile a partir do input `pi`.
  # A versão passa a ser controlada por `nix flake update pi`.
  #
  # Este módulo é o `lukasl-dev/pi.nix` (inputs.pi), não o módulo genérico
  # nix-community/home-manager `programs.pi-coding-agent`: `extensions` é uma
  # opção de nível superior (repassada como flags `--extension` a cada
  # invocação do `pi`), não uma chave dentro de `settings` — `settings` vira
  # literalmente o conteúdo de `~/.pi/agent/settings.json`, que o pi não lê
  # como fonte de extensions. Ver https://lukasl-dev.github.io/pi.nix/.
  programs.pi.coding-agent = {
    enable = true;
    package = inputs.pi.packages.${pkgs.system}.coding-agent;

    # O pi-jev-agent só registra /jev-status e ativa o roteamento quando esta
    # variável já está presente no processo que inicia o Pi. Mantê-la no
    # wrapper declarativo evita perder o comando depois de um rebuild.
    # A credencial TypeSafe continua fora do repositório e é herdada do
    # ambiente/gerenciador de segredos do usuário.
    environment.PI_JEV_ENABLED.value = "1";
  };
}
