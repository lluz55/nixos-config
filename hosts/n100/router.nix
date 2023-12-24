{ config, lib, pkgs, ... }:
let
  # Important ports 
  tailscale_port = toString config.services.tailscale.port;
  ssh_port = "22";
  frigate_port = "5000";
  ntp_port = "123";
  hass_port = "8123";
  zb2m_port = "1883";
  mosh_ports = "60000-61000";

  # Interfaces
  WAN = "enp1s0";
  LAN0 = "enp2s0";
  LAN1 = "enp3s0";
  LAN2 = "enp4s0";
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
    interfaces."${LAN0}".wakeOnLan.enable = true;
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
            devices = { "${WAN}", "${LAN0}", "${LAN1}", "${LAN2}"};
          }
          chain output {
            type filter hook output priority 100; policy accept;
          }
          chain input {
            type filter hook input priority 0; policy drop;
            iifname { "br-lan", "br-cams", "vl-mgmt"} accept comment "Allow local network to access the router"

            # Guests and Home networks
            iifname {"vl-guests", "vl-home"} udp dport 67-68 accept
            iifname {"vl-guests", "vl-home"} meta l4proto { udp, tcp} th dport 53 accept
            iifname "vl-guests" oifname { "vl-guests", "vl-home", "vl-mgmt", "br-cams", "br-lan"} drop comment "Block access to other networks"
            iifname "vl-home" oifname { "vl-guests", "vl-mgmt", "br-cams"} drop comment "Block access to other networks"

            iifname "${WAN}" ct state { established, related } accept comment "Allow established traffic"
            iifname "${WAN}" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
            iifname "lo" accept comment "Accept everything from loopback interface"

            # Allow ports on WAN interface
            tcp dport ${ssh_port} ct state new limit rate 2/minute accept comment "Accept SSH and avoid brute force"
            tcp dport ${hass_port} accept comment "Accept Homeassistant"
            tcp dport ${zb2m_port} accept comment "Accept Zigbee2mqtt"
            udp dport ${mosh_ports} accept comment "Accept Mosh"
            tcp dport ${frigate_port} accept comment "Accept Frigate"
            udp dport ${tailscale_port} accept comment "Accept Tailscale"
          }
          chain forward {
            type filter hook forward priority 0; policy drop;
            ip protocol tcp flow add @f comment "Offload tcp/udp established traffic"
            ct status dnat accept comment "Allow NAT through interfaces"

            iifname { "br-cams" } oifname { "${WAN}" } udp dport ${ntp_port} accept comment "Allow NTP extenal access"
            iifname { "br-cams" } ip saddr 10.1.1.10 oifname { "${WAN}" } accept comment "Allow Frigate extenal access"
            iifname { "br-lan", "vl-mgmt",  "vl-guests"} oifname { "${WAN}" } accept comment "Allow trusted LAN to ${WAN} (external access)"
            iifname { "${WAN}" } oifname {  "br-lan", "vl-mgmt", "br-cams", "vl-home", "vl-guests" } ct state { established, related } accept comment "Allow established back to LANs"
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
            tcp dport 4822 dnat 192.168.1.120 # TODO: Remove after tests
            tcp dport 3389 dnat 192.168.1.120 # TODO: Remove after tests
            tcp dport 5900-5999 dnat 192.168.1.120 comment "Allow VNC access to server" # TODO: Remove after tests
          }
          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;
            oifname "${WAN}" masquerade
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
      "10-${WAN}" = {
        matchConfig.Name = "${WAN}";
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
      "30-${LAN0}" = {
        matchConfig.Name = "${LAN0}";
        networkConfig = {
          Bridge = "br-lan";
          ConfigureWithoutCarrier = true;
        };
        linkConfig.RequiredForOnline = "enslaved";
      };
      "30-${LAN1}" = {
        matchConfig.Name = "${LAN1}";
        networkConfig = {
          Bridge = "br-cams";
          ConfigureWithoutCarrier = true;
        };
        linkConfig.RequiredForOnline = "enslaved";
      };
      "30-${LAN2}" = {
        matchConfig.Name = "${LAN2}";
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
  services.resolved.enable = false;

  systemd.services.allowDevicesHome = {
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.nftables}/bin/nft add rule ip filter forward iifname "vl-home" ether saddr {\
      ${lib.strings.concatMapStrings (x: "$(cat " + x + "), ")[
        config.sops.secrets.poco-mac.path 
        config.sops.secrets.gl62m-mac.path 
        config.sops.secrets.rn10c-mac.path 
        config.sops.secrets.b450-mac.path 
      ]} \
      } oifname "${WAN}" accept
    '';
  };

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
        #"${b450-mac},b450,192.168.1.120,infinite"
        ## Main smartphone
        #"${poco-mac},POCO_X3,10.0.66.2,infinite"
        #"${poco-mac},POCO_X3,10.0.55.2,infinite"
        ## Main Note
        #"${gl62m-mac},Gl62m,10.0.66.3,infinite"
        #"${gl62m-mac},Gl62m,10.0.55.3,infinite"

        # Wife's smartphone
        #"${rn10c-mac},rn10c,10.0.55.4, infinite"
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
