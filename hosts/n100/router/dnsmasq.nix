{ config, ... }:
{
  services.dnsmasq = {
    enable = true;
    settings = {
      # upstream DNS servers
      server = [ "8.8.8.8" "1.1.1.1" ];
      # sensible behaviours
      domain-needed = true;
      bogus-priv = true;
      no-resolv = true;

      # Cache dns queries.
      cache-size = 1000;

      dhcp-range = [
        "br-lan,192.168.1.100,192.168.1.150,24h"
        "br-cams,10.1.1.100,10.1.1.150,24h"
        "vl-mgmt,10.0.66.100,10.0.66.150,24h"
        "vl-home,10.0.55.100,10.0.55.150,24h"
        "vl-guests,10.0.10.100,10.0.10.150,24h"
      ];
      dhcp-host = [
        "192.168.1.1"
        "10.0.66.1"
        "10.0.55.1"
        "10.0.10.1"
        "10.1.1.1"

        # DHCP Leases
        # Main PC
        "${config.macs.b450},b450,192.168.1.120,infinite"
        ## Main smartphone
        "${config.macs.poco},POCO_X3,10.0.66.2,infinite"
        "${config.macs.poco},POCO_X3,10.0.55.2,infinite"
        ## Main Note
        "${config.macs.gl62m},Gl62m,10.0.66.3,infinite"
        "${config.macs.gl62m},Gl62m,10.0.55.3,infinite"

        # Wife's smartphone
        "${config.macs.rn10c},rn10c,10.0.55.4, infinite"

        "da:91:24:fb:3d:bf,homelab,10.1.1.10,infinite"
      ];

      # local domains
      local = "/lan/";
      domain = "lan";
      expand-hosts = true;

      # don't use /etc/hosts as this would advertise n100 as localhost
      no-hosts = true;
      address = [ "/home.lan/10.0.66.1" ];
    };
  };
}
