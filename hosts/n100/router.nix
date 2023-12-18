{ config, ... }:
let
  tailscale_port = toString config.services.tailscale.port;
  ssh_port = "22";
  frigate_port = "5000";
  ntp_port = "123";
  hass_port = "8123";
  zb2m_port = "1883";
  mosh_ports = "60000-61000";
in
{
  boot = {
    kernel = {
      sysctl = {
        "net.ipv4.conf.all.forwarding" = true;
        "net.ipv6.conf.all.forwarding" = true;
        "net.ipv4.ip_forward" = 1;
      };
    };
  };
  networking = {
    hostName = "n100";
    useNetworkd = true;
    useDHCP = false;
    interfaces."enp2s0".wakeOnLan.enable = true;
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

            iifname { "br-lan", "iot-10", "br-cams"} accept comment "Allow local network to access the router"
            iifname "enp1s0" ct state { established, related } accept comment "Allow established traffic"
            iifname "enp1s0" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
            iifname "lo" accept comment "Accept everything from loopback interface"

            # Allow ports on WAN interfaces
            tcp dport ${ssh_port} ct state new limit rate 2/minute accept comment "Accept SSH and avoid brute force"
            tcp dport ${hass_port} accept comment "Allow Homeassistant"
            tcp dport ${zb2m_port} accept comment "Zigbee2mqtt"
            udp dport ${mosh_ports} accept comment "Allow Mosh"
            tcp dport ${frigate_port} accept comment "Allow Frigate"
            udp dport ${tailscale_port} accept comment "Allow Tailscale"

          }
          chain forward {
            type filter hook forward priority 0; policy drop;
            ip protocol tcp flow add @f comment "Offload tcp/udp established traffic"
            ct status dnat accept comment "Allow NAT through interfaces"

            iifname { "br-cams" } oifname { "enp1s0" } udp dport ${ntp_port} accept comment "Allow NTP extenal access"
            iifname { "br-cams" } ip saddr 10.1.1.10 oifname { "enp1s0" } accept comment "Allow NTP extenal access"
            iifname { "br-lan", "iot-10" } oifname { "enp1s0" } accept comment "Allow trusted LAN to enp1s0"
            iifname { "enp1s0" } oifname {  "br-lan", "iot-10", "br-cams" } ct state { established, related } accept comment "Allow established back to LANs"
          }
        }

        table ip nat {
          chain prerouting {
            type nat hook prerouting priority dstnat; policy accept;
            tcp dport 10011 dnat 10.1.1.11:80 # TODO: Change to new default lan 
            tcp dport 10012 dnat 10.1.1.12:80 # TODO: Change to new default lan
            tcp dport 8123 dnat 10.1.1.10:8123 # TODO: Remove after tests
            tcp dport 8080 dnat 10.1.1.10:8080 # TODO: Remove after tests
            tcp dport 20022 dnat 192.168.1.120:22 # TODO: Remove after tests
            tcp dport 4822 meta nftrace set 1 dnat 192.168.1.120 # TODO: Remove after tests
            tcp dport 3389 meta nftrace set 1 dnat 192.168.1.120 # TODO: Remove after tests
            tcp dport 5900-5999 meta nftrace set 1 dnat 192.168.1.120 comment "Allow VNC access to server" # TODO: Remove after tests
          }
          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;
            oifname "enp1s0" masquerade
          } 
        }
      '';
    };
  };
  #tcp dport 80 meta nftrace set 1 dnat 10.1.1.9
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
          Kind = "bridge";
          #Kind = "vlan";
          Name = "iot-10";
        };
        #vlanConfig.Id = 10;
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
        #vlan = [ "iot-10" ];
        networkConfig = {
          Bridge = "iot-10";
          ConfigureWithoutCarrier = true;
        };
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
      "70-iot-10" = {
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
        "b4:2e:99:f4:ba:f3,b450,192.168.1.120,infinite"
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

