{ config, lib, pkgs, unstable ? pkgs, ... }:
with lib;
let
  cfg = config.cloudflaredConnectors;

  tunnelSubmodule = types.submodule ({ name, ... }: {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable this cloudflared tunnel instance.";
      };

      tunnelName = mkOption {
        type = types.str;
        default = name;
        description = "Cloudflare tunnel name.";
      };

      tokenSopsKey = mkOption {
        type = types.str;
        default = "cloudflare/tunnels/${name}/token";
        description = "sops-nix key path containing this tunnel token.";
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Additional arguments passed to cloudflared for this tunnel.";
      };
    };
  });

  enabledTunnels = filterAttrs (_: tunnelCfg: tunnelCfg.enable) cfg.tunnels;

  mkExtraArgs = tunnelCfg:
    concatStringsSep " " (map escapeShellArg (cfg.extraArgs ++ tunnelCfg.extraArgs));
in
{
  options.cloudflaredConnectors = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable cloudflared multi-tunnel connector services.";
    };

    package = mkOption {
      type = types.package;
      default = unstable.cloudflared;
      description = "cloudflared package to run.";
    };

    domainBaseSopsKey = mkOption {
      type = types.str;
      default = "cloudflare/tunnels/domain_base";
      description = "sops-nix key path containing the tunnels base domain.";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ "--no-autoupdate" ];
      description = "Arguments passed to all tunnel instances.";
    };

    tunnels = mkOption {
      type = types.attrsOf tunnelSubmodule;
      default = { };
      description = "Set of cloudflared tunnel definitions.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = enabledTunnels != { };
        message = "cloudflaredConnectors.enable requires at least one entry in cloudflaredConnectors.tunnels.";
      }
    ];

    sops.secrets =
      { ${cfg.domainBaseSopsKey} = { }; }
      // mapAttrs'
      (_: tunnelCfg: nameValuePair tunnelCfg.tokenSopsKey { })
      enabledTunnels;

    systemd.services = mapAttrs'
      (name: tunnelCfg:
        let
          serviceName = "cloudflared-connector-${name}";
          tunnelTokenPath = config.sops.secrets.${tunnelCfg.tokenSopsKey}.path;
          domainBasePath = config.sops.secrets.${cfg.domainBaseSopsKey}.path;
          allArgs = mkExtraArgs tunnelCfg;
          runScript = pkgs.writeShellScript "run-${serviceName}" ''
            domain_base="$(tr -d '\n' < ${escapeShellArg domainBasePath})"
            if [ -z "$domain_base" ]; then
              echo "cloudflared: domain base secret is empty (${cfg.domainBaseSopsKey})" >&2
              exit 1
            fi

            tunnel_hostname="${tunnelCfg.tunnelName}.$domain_base"
            echo "cloudflared: starting tunnel ${tunnelCfg.tunnelName} ($tunnel_hostname)"

            exec ${cfg.package}/bin/cloudflared ${allArgs} tunnel run --token "$(<${escapeShellArg tunnelTokenPath})"
          '';
        in
        nameValuePair serviceName {
          description = "cloudflared connector for ${tunnelCfg.tunnelName}";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];

          serviceConfig = {
            Type = "simple";
            Restart = "always";
            RestartSec = "5s";
            ExecStart = runScript;
          };
        })
      enabledTunnels;
  };
}
