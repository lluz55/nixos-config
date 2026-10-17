# AionUi — control plane web para os agentes CLI locais.
#
# Este módulo sobe o BACKEND do AionUi (o binário Rust `aioncore`), que é o
# que fala ACP com os agentes e serve a API/HTTP. Ele roda sem Electron e sem
# display: `aioncore --help` sozinho já sobe o servidor.
#
# ## Por que um input separado
#
# A tag de release do AionCore vem em `inputs.aioncore` (flake = false, pois o
# upstream é um projeto Rust puro sem flake.nix). A versão é lida do
# `Cargo.toml` desse input pinado, então a URL do asset e o input nunca
# divirgem por descuido. Isso mantém o pin do AionUi fora do ciclo do nixpkgs:
# `nix flake update aioncore` atualiza só ele.
#
# ## Escopo atual: backend sem frontend
#
# O que sobe aqui é o backend. A UI web em si (o renderer) é um bundle Bun
# que o upstream constrói a partir do monorepo AionUi e **não publica em
# lugar nenhum** — `@aionui/web-host` e `@aionui/web-cli` são `private: true`.
# Sem o renderer, o backend ainda serve a API e responde em
# /api, mas não há tela para navegar. Para a interface completa, ou você
# empacota o renderer (fase 2, exige bun), ou usa `bun run webui` direto de um
# checkout do AionUi apontando `AIONUI_BACKEND_BIN` para este serviço.
#
# ## Agentes
#
# O backend detecta os CLIs por $PATH — confirmei com `aioncore doctor`, que
# imprime a tabela de disponibilidade. O que ele enxerga hoje nesta máquina:
# codex, opencode, pi e antigravity (agy), todos nativos do catálogo. `mcode`
# NÃO está no catálogo de agentes: registre em
# Settings → Agent Management → Custom Agents com command `mcode` e args `acp`.
# Como `mcode acp` é um servidor ACP sobre stdio, ele entra sem gambiarra.
#
#É por isso que o `path` abaixo do serviço importa tanto: no shell você tem
# shell profile no PATH, mas o systemd não. Sem o path explícito, o `doctor`
# roda com PATH de sistema e reporta quase tudo como missing.
# `antigravity-cli` e `minimax-code-pkg` chegam por specialArgs do flake.nix.
# Precisam estar declarados aqui: o `...` da assinatura NÃO cria binding para
# argumentos desconhecidos, só os tolera.
{
  config,
  lib,
  pkgs,
  inputs,
  antigravity-cli,
  minimax-code-pkg,
  ...
}: let
  cfg = config.services.aionui;

  # Lê a versão direto do input pinado (ver comentário do topo). O layout do
  # Cargo.toml já mudou uma vez upstream ([workspace] -> [workspace.package]),
  # então aceitamos os dois formatos.
  aioncoreToml = lib.fromTOML (builtins.readFile "${inputs.aioncore}/Cargo.toml");
  aioncoreVersion = aioncoreToml.workspace.package.version or aioncoreToml.workspace.version;

  aioncore = pkgs.callPackage ../aioncore/package.nix {
    version = aioncoreVersion;
    # Para trocar a versão, atualize o hash com:
    #   nix run nixpkgs#nix-prefetch-url -- \
    #     "https://github.com/iOfficeAI/AionCore/releases/download/v<VER>/aioncore-v<VER>-x86_64-unknown-linux-gnu.tar.gz"
    hash = "sha256-FXJ6Qy7Ck1kEZ1F9I5nqPbKx+PIAvzUaVJSUGW58+sg=";
  };

  isLoopback = host:
    builtins.elem host [
      "127.0.0.1"
      "::1"
      "localhost"
    ];
in {
  options.services.aionui = {
    enable = lib.mkEnableOption "AionUi backend (aioncore) — web control plane para agentes CLI locais via ACP";

    package = lib.mkOption {
      type = lib.types.package;
      default = aioncore;
      defaultText = lib.literalExpression "aioncore (do input aioncore pinado na tag de release)";
      description = "Backend Rust do AionUi. Foi testado com aioncore ${aioncoreVersion}.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        Endereço de bind (--host). Mantenha em 127.0.0.1 e exponha por
        túnel autenticado: o backend consegue spawnar qualquer CLI do seu
        PATH, então escutar numa interface exposta equivale a dar execução
        de código remoto na máquina.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 25808;
      description = "Porta HTTP/API do backend (--port). É a porta que o AionUi serve, não o backend Rust cru.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "lluz";
      description = "Usuário sob o qual o backend roda. Precisa ser o dono de ~/.codex, ~/.config/opencode, ~/.pi e dos wrappers dos agentes, senão a detecção falha ou os agentes não acham as credenciais.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/${cfg.user}/.aionui";
      defaultText = lib.literalExpression "''/home/''${cfg.user}/.aionui";
      description = "Diretório de dados: banco SQLite, config e logs (--data-dir). Precisa ser persistente.";
    };

    workDir = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Diretório de trabalho padrão das conversas (--work-dir). Vazio
        deixa o próprio backend cair no data-dir.
      '';
    };

    identityMode = lib.mkOption {
      type = lib.types.enum [
        "webui"
        "local"
        "aionpro"
      ];
      default = "webui";
      description = ''
        Modo de identidade do BACKEND (--identity-mode). Só se aplica quando
        mode = "backend": no modo "web" é o aionui-web quem gerencia a auth e
        imprime a senha de admin na primeira subida.
        - "webui": JWT + senha. É o modo correto para uso self-hosted.
        - "local": **desliga a autenticação** por completo e usa um usuário
          sistema. Só faz sentido em 127.0.0.1 atrás de túnel.
        - "aionpro": exige AIONCORE_BOOTSTRAP_SECRET; não é o seu caso.
      '';
    };

    mode = lib.mkOption {
      type = lib.types.enum [
        "web"
        "backend"
      ];
      default = "web";
      description = ''
        O que o serviço expõe:
        - "web": a stack completa (aionui-web) — serve a UI estática, faz
          proxy da API e sobe o aioncore em porta interna. É o que dá acesso
          pelo navegador.
        - "backend": só o aioncore, API pura sem tela. Útil se a UI for
          servida por outro processo.
      '';
    };

    webPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../aionui-web/package.nix {};
      defaultText = lib.literalExpression "aionui-web (asset de release do AionUi)";
      description = "Renderer estático + host HTTP do AionUi. Só é usado no mode = \"web\".";
    };

    logLevel = lib.mkOption {
      type = lib.types.str;
      default = "info";
      example = "info,aionui_mcp=trace";
      description = "Filtro de log (--log-level). Aceita pares módulo=nível para rastrear um subsystem só.";
    };

    managedResourcesMode = lib.mkOption {
      type = lib.types.enum [
        "download"
        "bundled"
      ];
      default = "download";
      description = ''
        Origem dos recursos de runtime gerenciados
        (--managed-resources-mode). "download" busca em runtime (padrão do
        upstream, precisa de rede). "bundled" usa o bundle embutido, que
        este empacotamento não fornece — deixe "download".
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        # No modo web é o aionui-web que gerencia a autenticação e imprime a
        # senha de admin na primeira subida. Configurar identityMode = "local"
        # ali seria silenciosamente ignorado e daria a impressão de que a
        # autenticação está desligada — o oposto do que acontece.
        assertion = !(cfg.mode == "web" && cfg.identityMode != "webui");
        message = ''
          services.aionui: mode = "web" não usa identityMode — quem gerencia a
          auth é o aionui-web, que exige senha. Você configurou
          identityMode = "${cfg.identityMode}". Use mode = "backend" se quiser
          rodar o aioncore puro com esse modo.
        '';
      }
      {
        # --local desliga a autenticação. Se ele estiver ligado e a porta
        # escutar fora do loopback, qualquer um na rede pega um shell com as
        # suas credenciais. Melhor falhar no build do que expor assim.
        assertion = !(cfg.identityMode == "local" && !isLoopback cfg.host);
        message = ''
          services.aionui: identityMode = "local" desliga a autenticação e
          só pode ser usado com host em 127.0.0.1/::1. Você configurou
          host = "${cfg.host}". Mantenha o bind no loopback e exponha por
          túnel autenticado, ou use identityMode = "webui".
        '';
      }
    ];

    systemd.services.aionui = {
      description = "AionUi backend (aioncore) — control plane web dos agentes CLI";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];

      environment = {
        HOME = "/home/${cfg.user}";
        AIONUI_DATA_DIR = cfg.dataDir;
      };

      # O backend sonda os CLIs por $PATH e o systemd não carrega shell profile,
      # então sem esta lista o `doctor` reporta quase todo agente como missing
      # mesmo com tudo instalado.
      #
      # A opção `path` aceita pacotes OU caminhos absolutos, e em ambos os
      # casos deriva o diretório real anexando "/bin" (e "/sbin"). Por isso os
      # dois últimos itens são diretório-PAI: "/home/lluz/.local" vira
      # "/home/lluz/.local/bin". Passar o "/bin" aqui renderizaria
      # ".../bin/bin", que não existe. /etc/profiles/per-user traz codex e
      # claude; ~/.local/bin traz o agy 1.2.15 e os CLIs instalados à mão
      # (qwen, kiro-cli-chat).
      path = [
        cfg.package
        pkgs.nodejs
        pkgs.git
        pkgs.ripgrep
        pkgs.which
        pkgs.bash
        pkgs.coreutils
        pkgs.opencode
        antigravity-cli
        minimax-code-pkg
        "/etc/profiles/per-user/${cfg.user}"
        "/home/${cfg.user}/.local"
      ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        WorkingDirectory = "/home/${cfg.user}";

        # O aionui-web não sai no SIGTERM quando o systemd usa o KillMode
        # padrão (control-group): ele e o filho aioncore recebem o sinal ao
        # mesmo tempo, o aionui-web entende que o filho morreu e RESPAWNA um
        # novo aioncore em vez de encerrar. Resultado: o processo nunca sai e
        # todo restart trava pelos 90s do TimeoutStopSec.
        #
        # Testei em isolamento: com SIGTERM sozinho (sem o cgroup inteiro) o
        # aionui-web morre em menos de 6s. "mixed" envia SIGTERM só ao processo
        # principal e deixa o SIGKILL final para o resto do cgroup, então ele
        # encerra o filho com calma e sai. O TimeoutStopSec curto é a rede de
        # segurança: se mesmo assim travar, custa 15s em vez de 90.
        KillMode = "mixed";
        TimeoutStopSec = "15s";

        Restart = "on-failure";
        RestartSec = "5s";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${cfg.dataDir}";
        # String única, não lista: a opção ExecStart do NixOS renderiza uma
        # linha `ExecStart=` POR ELEMENTO da lista, e systemd só aceita uma
        # (fora de Type=oneshot) — a unidade era recusada na hora com
        # "Service has more than one ExecStart= setting".
        ExecStart =
          if cfg.mode == "web"
          then
            # O aionui-web não tem --host: escuta no loopback por padrão e
            # aceita --remote para virar 0.0.0.0. O backend entra por
            # --backend-bin apontando para o aioncore pinado no input, que ele
            # sobe numa porta interna à sua escolha.
            lib.concatStringsSep " " (
              [
                "${lib.getExe cfg.webPackage}"
                "start"
                "--port ${toString cfg.port}"
                "--data-dir ${cfg.dataDir}"
                "--backend-bin ${lib.getExe cfg.package}"
              ]
              ++ lib.optional (!isLoopback cfg.host) "--remote"
            )
          else
            lib.concatStringsSep " " (
              [
                "${lib.getExe cfg.package}"
                "--host ${cfg.host}"
                "--port ${toString cfg.port}"
                "--data-dir ${cfg.dataDir}"
                "--log-level ${cfg.logLevel}"
                "--identity-mode ${cfg.identityMode}"
                "--managed-resources-mode ${cfg.managedResourcesMode}"
                "--app-version ${cfg.package.version}"
              ]
              ++ lib.optional (cfg.workDir != "") "--work-dir ${cfg.workDir}"
            );
      };
    };
  };
}
