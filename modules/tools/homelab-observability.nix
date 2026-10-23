{ config, lib, ... }:
let
  cfg = config.homelabObservability;
in
{
  options.homelabObservability = {
    enable = lib.mkEnableOption "lightweight homelab observability with Prometheus and node_exporter";

    prometheus = {
      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = lib.mdDoc "Address where the local Prometheus server listens.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 9090;
        description = lib.mdDoc "TCP port for the local Prometheus server.";
      };
    };

    nodeExporter = {
      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = lib.mdDoc "Address where node_exporter listens.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 9002;
        description = lib.mdDoc "TCP port for node_exporter.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      listenAddress = cfg.prometheus.listenAddress;
      port = cfg.prometheus.port;
      globalConfig.scrape_interval = "30s";
      scrapeConfigs = [
        {
          job_name = "${config.networking.hostName}-node";
          static_configs = [
            {
              targets = [
                "${cfg.nodeExporter.listenAddress}:${toString cfg.nodeExporter.port}"
              ];
              labels = {
                host = config.networking.hostName;
                role = "homelab-observability-tracer";
              };
            }
          ];
        }
      ];

      exporters.node = {
        enable = true;
        listenAddress = cfg.nodeExporter.listenAddress;
        port = cfg.nodeExporter.port;
        openFirewall = false;
        enabledCollectors = [
          "cpu"
          "diskstats"
          "filesystem"
          "loadavg"
          "meminfo"
          "netdev"
          "netstat"
          "pressure"
          "stat"
          "systemd"
          "time"
          "uname"
        ];
      };
    };
  };
}
