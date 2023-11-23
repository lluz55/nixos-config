{ ... }:
{
  boot = {
    kernel = {
      sysctl = {
        "net.ipv4.conf.all.forwarding" = true;
        "net.ipv6.conf.all.forwarding" = true;
        "net.ipv4.conf.br-lan.rp_filter" = 1;
        "net.ipv4.conf.enp1s0.rp_filter" = 1;
      };
    };
  };
  networking = {
    hostName = "n100";
    useNetworkd = true;
    useDHCP = false;

    # No local firewall.
    nat.enable = false;
    firewall.enable = false;

    nftables = {
      enable = true;
      checkRuleset = false;
      ruleset = ''
        table ip filter {
          flowtable f {
            hook ingress priority 0; 
            devices = { "enp1s0", "enp2s0", "enp3s0", "enp4s0"};
          }
          chain output {
            type filter hook output priority 100; policy accept;
          }
          chain input {
            type filter hook input priority 0; policy drop;

            iifname { "br-lan", "iot-10", "br-cams" } accept comment "Allow local network to access the router"
            iifname "enp1s0" ct state { established, related } accept comment "Allow established traffic"
            iifname "enp1s0" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
            iifname "enp1s0" counter drop comment "Drop all other unsolicited traffic from enp1s0"
            iifname "lo" accept comment "Accept everything from loopback interface"
          }
          chain forward {
            type filter hook forward priority 0; policy drop;
            ip protocol tcp flow add @f comment "Offload tcp/udp established traffic"

            iifname { "br-lan", "iot-10"} oifname { "enp1s0" } accept comment "Allow trusted LAN to enp1s0"
            iifname { "enp1s0" } oifname { "br-lan", "iot-10", "br-cams" } ct state { established, related } accept comment "Allow established back to LANs"
          }
        }
        
        table ip nat {
          chain prerouting {                
            type nat hook prerouting priority 0; policy accept;
            tcp dport { 5000 } log prefix "nat-pre " dnat 127.0.0.1:5000;
          }
          chain postrouting {
            type nat hook postrouting priority 100; policy accept;
            tcp dport { 5000 } log prefix "nat-post ";
            oifname "enp1s0" masquerade
          } 
        }
      '';
    };
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
      "50-iot-10" = {
        netdevConfig = {
          Kind = "vlan";
          Name = "iot-10";
        };
        vlanConfig.Id = 10;
      };
    };
    networks = {
      # Connect the bridge ports to the bridge
      "30-enp2s0" = {
        matchConfig.Name = "enp2s0";
        networkConfig = {
          Bridge = "br-lan";
          ConfigureWithoutCarrier = true;
        };
        linkConfig.RequiredForOnline = "enslaved";
      };
      "30-enp3s0" = {
        matchConfig.Name = "enp3s0";
        networkConfig = {
          Bridge = "br-cams";
          ConfigureWithoutCarrier = true;
        };
        linkConfig.RequiredForOnline = "enslaved";
      };
      "30-enp4s0" = {
        matchConfig.Name = "enp4s0";
        vlan = [ "iot-10" ];
        #networkConfig = {
        #  Bridge = "br-lan";
        #  ConfigureWithoutCarrier = true;
        #};
        linkConfig.RequiredForOnline = "enslaved";
      };
      # Configure the bridge for its desired function
      "40-br-lan" = {
        matchConfig.Name = "br-lan";
        bridgeConfig = { };
        address = [
          "192.168.1.1/24"
        ];
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
        # Don't wait for it as it also would wait for wlan and DFS which takes around 5 min 
        linkConfig.RequiredForOnline = "no";
      };
      "50-iot-10" = {
        matchConfig.Name = "iot-10";
        bridgeConfig = { };
        address = [
          "10.0.10.1/24"
        ];
        networkConfig = {
          ConfigureWithoutCarrier = true;
        };
        # Don't wait for it as it also would wait for wlan and DFS which takes around 5 min 
        linkConfig.RequiredForOnline = "no";
      };
      "10-enp1s0" = {
        matchConfig.Name = "enp1s0";
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
    };
  };
  services.resolved.enable = false;

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
        "iot-10,10.0.10.100,10.0.10.150,24h"
      ];
      interface = [ "br-lan" "iot-10" "br-cams" ];
      dhcp-host = [
        "192.168.1.1"
        "10.0.10.1"
        "10.1.1.1"
      ];

      # local domains
      local = "/lan/";
      domain = "lan";
      expand-hosts = true;

      # don't use /etc/hosts as this would advertise n100 as localhost
      no-hosts = true;
      address = "/n100.lan/192.168.1.1";
    };
  };

  # The service irqbalance is useful as it assigns certain IRQ calls to specific CPUs instead of letting the first CPU core to handle everything. This is supposed to increase performance by hitting CPU cache more often.
  services.irqbalance.enable = true;
}

