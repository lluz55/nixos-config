# Agent of Empires (AoE) — módulo NixOS para o web/TUI session manager.
#
# ## Por que isto aqui
# Acompanhia ao `aionui` no mesmo host sem brigar por porta (este escuta em
# 25809, AionUi continua em 25808). O objetivo é validar o AoE em paralelo
# com a stack atual, antes de qualquer migração.
#
# ## Custom agents via Nix
# O AoE lê `~/.config/agent-of-empires/config.toml` (segue XDG) e aceita
# custom agents em três sections:
#   - [session.custom_agents]    : nome → comando executado no tmux
#   - [session.agent_detect_as]  : nome → adapter built-in cuja detecção de
#                                  status Idle/Running/Waiting o agente herda
#   - [session.agent_acp_cmd]    : nome → comando ACP que o ativa no
#                                  structured view (plan panels, tool-call
#                                  cards, swipe-to-approve)
# O activation script abaixo lê essas três sections declaradas em Nix e
# escreve/mescla no config vivo, preservando todas as outras (default_tool,
# hooks, sandbox, worktree, profile defaults). O usuário pode ajustar essas
# outras pelo TUI/web wizard sem que o próximo rebuild as apague.
#
# ## Para o MiniMax Code (`mcode`)
# O comando abaixo mostra a configuração mínima que ativa mcode como
# custom agent com structured view ACP (herda o adapter built-in `claude`):
#
#   services.agent-of-empires.customAgents.minimax-code = {
#     command = "mcode";
#     detectAs = "claude";      # herda detecção de status
#     acpCommand = "mcode acp"; # structured view via ACP
#   };
#
# Antigravity CLI, Codex CLI e OpenCode já são detectados automaticamente
# quando estão no `path` (definido abaixo com os pacotes Nix).
{
  config,
  lib,
  pkgs,
  inputs,
  antigravity-cli,
  minimax-code-pkg,
  ...
}: let
  cfg = config.services.agent-of-empires;

  # `pkgs.formats.toml` (nixpkgs ≥ 23.11) gera TOML a partir de attrs e é
  # usado para renderizar APENAS as três sections que o Nix declara
  # (custom_agents, agent_detect_as, agent_acp_cmd). O merge com o config
  # vivo acontece no activation script — ver `mergeAoEConfig` abaixo.
  customAgentsFormat = pkgs.formats.toml {};
  customAgentsConfigFile =
    customAgentsFormat.generate "agent-of-empires-custom-agents.toml"
    {
      session = {
        custom_agents = lib.mapAttrs (_: v: v.command) cfg.customAgents;
        agent_detect_as = lib.filterAttrs (_: v: v.detectAs != null) (
          lib.mapAttrs (_: v: v.detectAs) cfg.customAgents
        );
        agent_acp_cmd = lib.filterAttrs (_: v: v.acpCommand != null) (
          lib.mapAttrs (_: v: v.acpCommand) cfg.customAgents
        );
      };
    };

  # Activation script: lê o seed TOML (com as três sections) e o live
  # config.toml existente, faz merge preservando outras sections, reescreve.
  # Implementado em Python porque tomllib (3.11+) é built-in e não exige
  # dependência adicional além do próprio python3.
  mergeAoEConfig = pkgs.writeScript "merge-aoe-custom-agents" ''
    #!${pkgs.python3}/bin/python3
    """
    Mescla as três sections declaradas em Nix ([session.custom_agents],
    [session.agent_detect_as], [session.agent_acp_cmd]) no config.toml vivo
    do Agent of Empires, preservando todas as outras sections alteradas em
    runtime (default_tool, hooks, sandbox, worktree, profile configs).

    Argumentos:
      sys.argv[1]: caminho do seed (TOML com as 3 sections Nix)
      sys.argv[2]: caminho do config.toml vivo
    """
    import pathlib
    import sys
    import tomllib

    MANAGED = ("custom_agents", "agent_detect_as", "agent_acp_cmd")

    seed_path = pathlib.Path(sys.argv[1])
    live_path = pathlib.Path(sys.argv[2])

    seed = tomllib.loads(seed_path.read_text()) if seed_path.exists() else {}
    live = tomllib.loads(live_path.read_text()) if live_path.exists() else {}

    # Sobrescreve as três keys gerenciadas dentro de [session] com o seed.
    # Demais keys de [session] (default_tool, etc.) e outras sections
    # (hooks, sandbox, worktree, ...) ficam intactas.
    live_session = live.setdefault("session", {})
    for key in MANAGED:
        if key in seed.get("session", {}):
            live_session[key] = seed["session"][key]

    # Renderiza TOML manualmente. Cobre o subconjunto que o AoE emite:
    # scalars (string/int/bool/float), arrays (`[ v1, v2 ]`), tabelas
    # inline (`{ k = v }`) e None. Para tipos não cobertos emite um
    # comentário de aviso em vez de quebrar a activation — melhor perder
    # uma chave rara do que falhar o rebuild inteiro.
    def render_str(s):
        return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'

    def render_v(v):
        if isinstance(v, bool):
            return "true" if v else "false"
        if isinstance(v, int):
            return str(v)
        if isinstance(v, float):
            return repr(v)
        if v is None:
            # TOML não tem null nativo; o AoE usa None só no seed (campo
            # detectAs / acpCommand filtrados). Não chega no live.
            return '""'
        if isinstance(v, list):
            # Array TOML básico: todos os itens escalares. O AoE emite
            # listas de strings (ex.: environment, volume_ignores).
            return "[" + ", ".join(render_v(item) for item in v) + "]"
        if isinstance(v, dict):
            # Tabela inline (não deveria ocorrer no top-level das
            # sections do AoE, mas tratamos para resiliência).
            return "{" + ", ".join(f"{k} = {render_v(val)}" for k, val in v.items()) + "}"
        if isinstance(v, str):
            return render_str(v)
        sys.stderr.write(
            f"merge-aoe-custom-agents: tipo TOML não suportado {type(v).__name__}={v!r}, ignorando\n"
        )
        return f'"<unsupported:{type(v).__name__}>"'

    out = []
    for section, body in live.items():
        if not isinstance(body, dict):
            out.append(f"{section} = {render_v(body)}")
            continue
        inline = {k: v for k, v in body.items() if isinstance(v, dict)}
        scalars = {k: v for k, v in body.items() if not isinstance(v, dict)}
        # Inline tables ficam sob [section.key] — preserva a estrutura que
        # o AoE usa para custom_agents, agent_detect_as, agent_acp_cmd.
        if inline:
            for sub, sub_body in inline.items():
                out.append(f"[{section}.{sub}]")
                for k, v in sub_body.items():
                    out.append(f"{k} = {render_v(v)}")
                out.append("")
        if scalars:
            out.append(f"[{section}]")
            for k, v in scalars.items():
                out.append(f"{k} = {render_v(v)}")
            out.append("")

    rendered = "\n".join(line for line in out if line).rstrip() + "\n"
    if live_path.exists() and live_path.read_text() == rendered:
        sys.exit(0)
    tmp = live_path.with_suffix(".toml.tmp")
    tmp.write_text(rendered)
    tmp.chmod(0o644)
    tmp.replace(live_path)
  '';

  # `pkgs.formats.toml` rejeita strings com espaços nos valores de tabelas
  # inline (e.g. `acpCommand = "mcode acp"`), portanto geramos o seed TOML
  # manualmente com `pkgs.writeText`. Renderizar inline tables manualmente
  # nos dá controle sobre aspas e escaping, e mantém a estrutura que o
  # Python merge script espera.
  #
  # ATENÇÃO à ordem: lib.filterAttrs recebe (name, value) onde value ainda
  # é o sub-set do customAgents (com command/acpCommand/detectAs), então
  # o predicado checa `v.detectAs != null` corretamente. Só depois o
  # lib.mapAttrs extrai o campo. Filtrar depois de mapear produziria
  # "expected a set but found a string" — o erro clássico desta armadilha.
  #
  # ATENÇÃO ao formato TOML: o [section.header] que vem logo antes das
  # chaves exige que CADA chave fique em sua própria linha. O `tomllib`
  # recusa `key1 = "v", key2 = "v2"` na mesma linha após um header (a
  # primeira tentativa terminou em "Expected newline or end of document
  # after a statement"). O `renderKeyValues` aqui emite uma chave por
  # linha, que é o que o `tomllib` aceita.
  renderKeyValues = tbl:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (k: v: "${k} = \"${v}\"") tbl
    );

  hasDetectAs = cfg.customAgents != {}
    && lib.any (v: v.detectAs != null) (lib.attrValues cfg.customAgents);
  hasAcpCommand = cfg.customAgents != {}
    && lib.any (v: v.acpCommand != null) (lib.attrValues cfg.customAgents);

  customAgentsTOML = pkgs.writeText "agent-of-empires-custom-agents.toml" (
    lib.concatStringsSep "\n" (
      lib.optional (cfg.customAgents != {}) "[session.custom_agents]"
      ++ lib.optional (cfg.customAgents != {}) (
        renderKeyValues (lib.mapAttrs (_: v: v.command) cfg.customAgents)
      )
      ++ lib.optional hasDetectAs ""
      ++ lib.optional hasDetectAs "[session.agent_detect_as]"
      ++ lib.optional hasDetectAs (
        renderKeyValues (
          lib.mapAttrs (_: v: v.detectAs)
            (lib.filterAttrs (_: v: v.detectAs != null) cfg.customAgents)
        )
      )
      ++ lib.optional hasAcpCommand ""
      ++ lib.optional hasAcpCommand "[session.agent_acp_cmd]"
      ++ lib.optional hasAcpCommand (
        renderKeyValues (
          lib.mapAttrs (_: v: v.acpCommand)
            (lib.filterAttrs (_: v: v.acpCommand != null) cfg.customAgents)
        )
      )
      ++ [ "" ]
    )
  );

  isLoopback = host:
    builtins.elem host [
      "127.0.0.1"
      "::1"
      "localhost"
    ];

  # configDir segue o XDG padrão do AoE em Linux
  configDir = "/home/${cfg.user}/.config/agent-of-empires";
in {
  options.services.agent-of-empires = {
    enable = lib.mkEnableOption ''
      Agent of Empires (AoE) — session manager TUI/web para os agentes CLI
      locais (Claude Code, Codex, OpenCode, Antigravity, MiniMax Code, ...).
    '';

    package = lib.mkOption {
      type = lib.types.package;
      default = inputs.agent-of-empires.packages.${pkgs.system}.aoe-with-web;
      defaultText = lib.literalExpression ''
        inputs.agent-of-empires.packages.\${pkgs.system}.aoe-with-web
      '';
      description = ''
        Derivação com o binário `aoe` (Rust + React frontend embedded via
        feature `serve`). O upstream mantém flake.nix nativo em
        `github:agent-of-empires/agent-of-empires`, então este default
        aponta para `inputs.agent-of-empires.packages.aoe-with-web` em
        vez de empacotar o binário pré-compilado. Pin a versão no flake
        com `inputs.agent-of-empires.url = ".../<tag>"`.
      '';
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        Endereço de bind do web dashboard (--host). Mantenha em 127.0.0.1 e
        exponha por túnel autenticado (dl-conn, SSH -L, Tailscale/Netbird):
        o AoE spawna qualquer CLI do PATH com as suas credenciais, então
        escutar fora do loopback equivale a dar execução de código remoto
        na máquina.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 25809;
      description = ''
        Porta do web dashboard (--port). Foi escolhida acima da 25808
        (AionUi) para coexistir sem conflito no mesmo host.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "lluz";
      description = ''
        User account sob o qual o serviço roda. Precisa ser o dono de
        ~/.codex, ~/.config/opencode, ~/.config/agent-of-empires, e dos
        wrappers dos agentes, senão a detecção falha ou os agentes não
        acham as credenciais.
      '';
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/${cfg.user}/.agent-of-empires";
      defaultText = lib.literalExpression "/home/\${cfg.user}/.agent-of-empires";
      description = ''
        Diretório de dados: SQLite, sessions, logs do `aoe serve` e odb .
        O AoE 1.18.0 não aceita `--data-dir` no `aoe serve`: ele resolve
        o local por `XDG_CONFIG_HOME` (default `~/.config`). Para mover
        de lugar, defina `xdgConfigHome` em vez deste campo.
      '';
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      default = configDir;
      defaultText = lib.literalExpression "/home/\${cfg.user}/.config/agent-of-empires";
      description = ''
        Diretório do config.toml (XDG_CONFIG_HOME/agent-of-empires). O
        activation script escreve o config vivo aqui, mesclando as três
        sections declaradas em Nix com o resto (default_tool, hooks, ...).
      '';
    };

    xdgConfigHome = lib.mkOption {
      type = lib.types.str;
      default = "/home/${cfg.user}/.config";
      defaultText = lib.literalExpression "/home/\${cfg.user}/.config";
      description = ''
        Valor de XDG_CONFIG_HOME exportado para o `aoe serve`. Move todos
        os dados (config.toml, sessions.db, locks) para
        `\$xdgConfigHome/agent-of-empires/`. Mude junto com `configDir`.
      '';
    };

    noAuth = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Quando true passa `--no-auth` ao `aoe serve` (apenas loopback).
        Default true porque o bind está em 127.0.0.1 e o acesso remoto
        passa por dl-conn/SSH-L/Tailscale. Para bind público prefira
        `--auth=token` (default upstream) e exponha pelo reverse-proxy.
      '';
    };

    webUI = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Quando true sobe `aoe serve` (TUI + web dashboard na porta escolhida).
        Quando false sobe só o `aoe` daemon local — útil em hosts sem
        display, mas perde o mobile dashboard.
      '';
    };

    logLevel = lib.mkOption {
      type = lib.types.str;
      default = "info";
      description = ''
        Filtro de log do daemon `aoe serve` (configurado em runtime via
        `aoe log-level <level>`). Não confundir com flags de CLI.
      '';
    };

    customAgents = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          command = lib.mkOption {
            type = lib.types.str;
            example = "mcode";
            description = ''
              Comando a executar no tmux para este agente. Aparece no
              picker do TUI e do web wizard com o nome do attrset.
            '';
          };
          acpCommand = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "mcode acp";
            description = ''
              Comando ACP que ativa o agente no structured view (seções
              plan, tool-call cards, swipe-to-approve). Se null, o agente
              roda em terminal view puro.
            '';
          };
          detectAs = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "claude";
            description = ''
              Nome de um agente built-in cuja heurística de detecção de
              status (Idle/Running/Waiting) este agente herda. Recomendado
              para qualquer wrapper que entrega um terminal de Claude, Codex
              ou OpenCode real — sem isto o status fica preso em "Idle".
            '';
          };
        };
      });

      default = {};
      example = lib.literalExpression ''
        {
          minimax-code = {
            command = "mcode";
            acpCommand = "mcode acp";
            detectAs = "claude";
          };
        }
      '';
      description = ''
        Agentes custom declarados em Nix. O activation script escreve
        [session.custom_agents], [session.agent_detect_as] e
        [session.agent_acp_cmd] no config.toml vivo, preservando outras
        sections.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        # O AoE TUI TAMBÉM escuta no `--host`, mas como o daemon não
        # implementa autenticação, expor uma porta com bind público é dar
        # execução de código na máquina. Mesmo aviso do AionUi.
        assertion = isLoopback cfg.host;
        message = ''
          services.agent-of-empires: host = "${cfg.host}" expõe o
          dashboard web sem autenticação. Use 127.0.0.1/::1 e exponha por
          túnel autenticado (dl-conn, SSH -L, Tailscale, Netbird). Para
          LAN confiável, prefira um reverse-proxy autenticado na frente.
        '';
      }
    ];

    # Cria os diretórios persistentes antes do start do serviço.
    systemd.tmpfiles.rules = [
      "d /home/${cfg.user}/.agent-of-empires 0750 ${cfg.user} users -"
      "d ${cfg.configDir} 0755 ${cfg.user} users -"
    ];

    # Mescla as três sections gerenciadas no config.toml vivo.
    # Roda na activation do Nix antes de qualquer service que dependa do
    # config (no caso, o systemd.service abaixo). Preserva default_tool,
    # hooks, sandbox, worktree, profiles alterados em runtime.
    system.activationScripts.agent-of-empires-config = {
      deps = [ "users" "groups" ];
      text = ''
        # O configDir é criado pelos systemd.tmpfiles.rules acima, MAS os
        # snippets de ativação rodam antes do systemd-tmpfiles-setup durante
        # o switch-to-configuration. Sem este install -d, o merge quebra com
        # FileNotFoundError em config.toml.tmp — foi o que derrubou o primeiro
        # rebuild do n100. Vale também para qualquer host novo, que nunca
        # passou por um boot que já tivesse criado o diretório.
        install -d -m 0755 -o ${cfg.user} -g users ${cfg.configDir}
        ${mergeAoEConfig} ${customAgentsTOML} ${cfg.configDir}/config.toml
        chown -R ${cfg.user}:users ${cfg.configDir}
        chmod 0644 ${cfg.configDir}/config.toml
      '';
    };

    systemd.services.agent-of-empires = {
      description = "Agent of Empires (AoE) — session manager web/TUI para agentes CLI";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      environment = {
        HOME = "/home/${cfg.user}";
        # XDG explícito para garantir o mesmo path em qualquer environment.
        # O AoE 1.18.0 lê o config e o SQLite de \$XDG_CONFIG_HOME/agent-of-empires/.
        XDG_CONFIG_HOME = cfg.xdgConfigHome;
        # Pré-configura o filtro de log para o daemon (default info); o
        # usuário ajusta em runtime via `aoe log-level <level>`. Não é uma
        # flag de CLI — é a env var que o EnvFilter consome.
        RUST_LOG = cfg.logLevel;
      };

      # O `aoe serve` spawna cada agente em tmux, então tmux é obrigatório.
      # Os pacotes abaixo entram para que `aoe agents` detecte o que está
      # instalado (sem isto systemd não carrega shell profile e quase todo
      # agente aparece como "missing").
      #
      # ATENÇÃO ao formato do `path`: systemd deriva o diretório real
      # anexando `/bin` (e `/sbin`). Por isso cada entrada abaixo é o
      # diretório-PAI do que precisa estar visível — passar `/bin` aqui
      # renderiza `…/bin/bin`, que não existe. Concretamente:
      #   - "/etc/profiles/per-user/${user}" cobre os pacotes que o
      #     home-manager instala via `environment.systemPackages`
      #     (codex, claude, pi).
      #   - "/run/current-system/sw" cobre os systemPackages NixOS
      #     (opencode, gemini, kiro-cli-chat, qwen, kimi, etc.). Sem
      #     isto, `aoe agents` reporta `opencode` como missing e o
      #     spawn do structured view aborta com "No such file or
      #     directory" — foi o bug do dia a mais que o mcode: opencode
      #     não tem `agent_acp_cmd` próprio, então o AoE tenta
      #     `opencode acp` e o kernel devolve ENOENT.
      #   - "/home/${user}/.local" cobre os pacotes instalados à mão
      #     em ~/.local/bin (agy 1.2.15 do Antigravity, qwen, etc.).
      path = [
        cfg.package
        pkgs.tmux
        pkgs.nodejs
        pkgs.git
        pkgs.ripgrep
        pkgs.which
        pkgs.bash
        pkgs.coreutils
        antigravity-cli
        minimax-code-pkg
        "/etc/profiles/per-user/${cfg.user}"
        "/run/current-system/sw"
        "/home/${cfg.user}/.local"
      ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        WorkingDirectory = "/home/${cfg.user}";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${cfg.dataDir}";

        # O tmux server é um processo separado que sobrevive ao ttimeout
        # do `aoe serve`. KillMode=mixed garante SIGTERM só ao processo
        # principal; o tmux herda o cgroup e recebe SIGKILL no final,
        # então as sessões abertas pelo usuário não morrem abruptamente
        # no meio de uma operação. TimeoutStopSec = 30s cobre o caso em
        # que o `aoe serve` trava esperando um lock.
        KillMode = "mixed";
        TimeoutStopSec = "30s";
        Restart = "on-failure";
        RestartSec = "5s";

        ExecStart = lib.concatStringsSep " " (
          [ "${lib.getExe cfg.package}" "serve"
              "--host ${cfg.host}"
              "--port ${toString cfg.port}"
            ]
          ++ lib.optional cfg.noAuth "--no-auth"
          ++ lib.optional cfg.webUI "--open"
        );
      };
    };
  };
}