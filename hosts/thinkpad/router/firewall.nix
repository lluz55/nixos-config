{ config, lib, ... }:
let
  cfg = config.cameraRouter;
in
with lib; {
  config = mkIf cfg.enable {
    boot = {
      kernelModules = [
        "nf_conntrack"
        "nf_nat"
        "nf_tables"
        "nft_chain_nat"
        "nft_masq"
      ];
      kernel.sysctl = {
        "net.ipv4.conf.all.forwarding" = if cfg.mode == "provisioning" then 1 else 0;
        "net.ipv4.ip_forward" = if cfg.mode == "provisioning" then 1 else 0;
        "net.ipv6.conf.all.forwarding" = 0;
      };
    };

    networking = {
      nftables = {
        enable = true;
        checkRuleset = false;
        ruleset = ''
          table inet filter {
            chain input {
              type filter hook input priority 0; policy accept;
            }

            chain forward {
              type filter hook forward priority 0; policy drop;

              # Allow camera AP to uplink
              iifname "${cfg.apInterface}" oifname "${cfg.uplinkInterface}" accept comment "Camera AP to uplink"

              # Allow return traffic from uplink to cameras
              iifname "${cfg.uplinkInterface}" oifname "${cfg.apInterface}" ct state established,related accept comment "Return traffic to cameras"
            }
          }
        '' + optionalString (cfg.mode == "provisioning") ''
          table ip nat {
            chain postrouting {
              type nat hook postrouting priority srcnat; policy accept;

              # Masquerade camera traffic going to uplink
              oifname "${cfg.uplinkInterface}" ip saddr ${cfg.subnet} masquerade comment "NAT camera to internet"
            }
          }
        '';
      };
    };
  };
}
