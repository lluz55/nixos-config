{ config, lib, pkgs, ... }:
let
  cfg = config.services.dsh;
  dsh-pkg = pkgs.callPackage ./package.nix { };

  # Um `lib.mkIf` só tem sentido dentro de `config`/de uma definição de
  # opção: o valor que ele devolve é um set { _type = "if"; ... } que o
  # módulo resolve depois. Interpolar isso numa string (era o caso na regra
  # tmpfiles abaixo) falha a avaliação com "cannot coerce a set to a
  # string". A condição vive na própria regra, via lib.optional.
  hasProviders = cfg.providers != null && cfg.providers != { };

  # O conteúdo vai para o /nix/store em vez de ser embutido na regra
  # tmpfiles: o argumento de uma regra "f" é uma linha só, então um JSON
  # com quebras de linha (ou com os espaços que o formato usa como
  # separador de campos) corromperia a regra.
  providersFile = pkgs.writeText "dsh-providers.json" (builtins.toJSON cfg.providers);

  # Caminho do arquivo de configuração no home do usuário
  configDir = "/home/${cfg.user}/.dsh";
  configFile = "${configDir}/providers.json";
in
{
  options.services.dsh = {
    enable = lib.mkEnableOption "DeepSeek Harness (dsh) web profile daemon";

    package = lib.mkOption {
      type = lib.types.package;
      default = dsh-pkg;
      description = "Package providing dsh.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3080;
      description = ''
        Listen port for `dsh --profile web`. The upstream web app refuses
        `--host 0.0.0.0` on purpose (would expose remote code execution to
        the network), so this service always binds 127.0.0.1 — reach it
        remotely via SSH port-forward, Tailscale/Netbird, or mosh, all
        already available on this host.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "lluz";
      description = "User account under which dsh runs (owns $HOME/.dsh).";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = config.users.users.${cfg.user}.group or "users";
      defaultText = lib.literalExpression "o grupo primário de services.dsh.user";
      description = ''
        Grupo dono de $HOME/.dsh. O default acompanha o grupo primário do
        próprio usuário; fixar um nome aqui só é necessário quando o
        usuário não é declarado neste sistema.
      '';
    };

    providers = lib.mkOption {
      type = lib.types.nullOr (lib.types.attrsOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Provider display name (e.g., '9router', 'OpenAI').";
          };
          baseURL = lib.mkOption {
            type = lib.types.str;
            description = "OpenAI-compatible API base URL (e.g., 'http://localhost:20128/v1').";
          };
          apiKey = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "API key (optional, if provider requires auth).";
          };
          models = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "List of model IDs to expose (empty = auto-discover).";
          };
        };
      }));
      default = null;
      description = ''
        Provedores OpenAI-compatíveis para pré-configurar no dsh.
        Exemplo:
          providers.9router = {
            name = "9router";
            baseURL = "http://localhost:20128/v1";
            apiKey = null;
            models = [ "deepseek-chat" "deepseek-coder" ];
          };
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Cria diretório e arquivo de configuração via systemd-tmpfiles
    systemd.tmpfiles.rules = [
      "d ${configDir} 0755 ${cfg.user} ${cfg.group} -"
    ] ++ lib.optional hasProviders
      # "C" copia só se o destino não existir, preservando edições feitas
      # em runtime; "L+" faria um symlink para o /nix/store (read-only).
      "C ${configFile} 0644 ${cfg.user} ${cfg.group} - ${providersFile}";

    systemd.services.dsh = {
      description = "DeepSeek Harness (dsh) web profile";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "systemd-tmpfiles-setup.service" ];
      wants = [ "network-online.target" ];

      path = with pkgs; [ nodejs_22 bash coreutils git ripgrep ];

      environment = {
        HOME = "/home/${cfg.user}";
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        WorkingDirectory = "/home/${cfg.user}";
        ExecStart = "${lib.getExe cfg.package} web --port ${toString cfg.port} --no-open";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}