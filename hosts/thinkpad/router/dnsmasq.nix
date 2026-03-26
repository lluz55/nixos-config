{ config, lib, ... }:
let
  cfg = config.cameraRouter;
  dhcpHosts = map (camera: "${camera.mac},${camera.name},${camera.ip},infinite") cfg.cameras;
in
with lib; {
  config = mkIf cfg.enable {
    services.dnsmasq = {
      enable = true;
      settings = {
        domain-needed = true;
        bogus-priv = true;
        no-resolv = true;
        all-servers = true;
        cache-size = 1000;
        bind-interfaces = true;
        # Não escutar em localhost para evitar conflito com NM dnsmasq
        except-interface = [ "lo" ];
        interface = [ cfg.apInterface ];
        listen-address = [ cfg.apAddress ];
        dhcp-range = [
          "${cfg.apInterface},${cfg.dhcpRangeStart},${cfg.dhcpRangeEnd},12h"
        ];
        dhcp-option = [
          "${cfg.apInterface},option:router,${cfg.apAddress}"
          "${cfg.apInterface},option:dns-server,${cfg.apAddress}"
        ];
        dhcp-host = dhcpHosts;
        # Use public DNS servers for camera internet access during provisioning
        server = cfg.dnsServers;
      };
    };

    # dnsmasq precisa da interface AP configurada (pelo hostapd)
    systemd.services.dnsmasq.after = [ "hostapd.service" ];
    systemd.services.dnsmasq.wants = [ "hostapd.service" ];
  };
}
