{ config, ... }:
{
  networking = {
    hostName = "n100";
    useNetworkd = true;
    useDHCP = false;
    interfaces.${config.LAN0}.wakeOnLan.enable = true;
    # No local firewall.
    nat.enable = false;
    firewall.enable = false;
  };

  systemd.network = {
    wait-online.anyInterface = true;
    netdevs = {
      # Create the bridge interface
      "20-br-lan" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br-lan";
        };
      };
      "30-br-cams" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br-cams";
        };
      };
      "40-vl-guests" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "vl-guests";
        };
        vlanConfig.Id = 10;
      };
      "50-vl-mgmt" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "vl-mgmt";
        };
        vlanConfig.Id = 66;
      };
      "60-vl-home" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "vl-home";
        };
        vlanConfig.Id = 55;
      };
    };
    networks = {
      "10-${config.WAN}" = {
        matchConfig.Name = "${config.WAN}";
        networkConfig = {
          # start a DHCP Client for IPv4 Addressing/Routing
          DHCP = "ipv4";
          # accept Router Advertisements for Stateless IPv6 Autoconfiguraton (SLAAC)
          IPv6AcceptRA = true;
          DNSOverTLS = true;
          DNSSEC = true;
          IPv6PrivacyExtensions = false;
          IPForward = true;
        };
        # make routing on this interface a dependency for network-online.target
        linkConfig.RequiredForOnline = "routable";
      };
      # Connect the bridge ports to the bridge
      "30-${config.LAN0}" = {
        matchConfig.Name = "${config.LAN0}";
        networkConfig = {
          Bridge = "br-lan";
          ConfigureWithoutCarrier = true;
        };
        linkConfig.RequiredForOnline = "enslaved";
      };
      "30-${config.LAN1}" = {
        matchConfig.Name = "${config.LAN1}";
        networkConfig = {
          Bridge = "br-cams";
          ConfigureWithoutCarrier = true;
        };
        linkConfig.RequiredForOnline = "enslaved";
      };
      "30-${config.LAN2}" = {
        matchConfig.Name = "${config.LAN2}";
        vlan = [ "vl-mgmt" "vl-home" "vl-guests" ];
        networkConfig = { };
        linkConfig.RequiredForOnline = "enslaved";
      };
      # Configure the bridge for its desired function
      "40-br-lan" = {
        matchConfig.Name = "br-lan";
        bridgeConfig = { };
        address = [
          "192.168.1.1/24"
        ];
        gateway = [ "192.168.100.1" ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
        };
        # Don't wait for it as it also would wait for wlan and DFS which takes around 5 min 
        linkConfig.RequiredForOnline = "no";
      };
      "60-br-cams" = {
        matchConfig.Name = "br-cams";
        bridgeConfig = { };
        address = [
          "10.1.1.1/24"
        ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
        };
        gateway = [ "192.168.100.1" ];
        # Don't wait for it as it also would wait for wlan and DFS which takes around 5 min 
        linkConfig.RequiredForOnline = "no";
      };
      "70-vl-mgmt" = {
        matchConfig.Name = "vl-mgmt";
        bridgeConfig = { };
        address = [
          "10.0.66.1/24"
        ];
        gateway = [ "192.168.100.1" ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
        };
        # Don't wait for it as it also would wait for wlan and DFS which takes around 5 min 
        linkConfig.RequiredForOnline = "no";
      };
      "80-vl-home" = {
        matchConfig.Name = "vl-home";
        bridgeConfig = { };
        address = [
          "10.0.55.1/24"
        ];
        gateway = [ "192.168.100.1" ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
        };
        # Don't wait for it as it also would wait for wlan and DFS which takes around 5 min 
        linkConfig.RequiredForOnline = "no";
      };
      "90-vl-guests" = {
        matchConfig.Name = "vl-guests";
        bridgeConfig = { };
        address = [
          "10.0.10.1/24"
        ];
        gateway = [ "192.168.100.1" ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
        };
        # Don't wait for it as it also would wait for wlan and DFS which takes around 5 min 
        linkConfig.RequiredForOnline = "no";
      };
    };
  };
}
