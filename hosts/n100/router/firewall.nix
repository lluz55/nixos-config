{ config, lib, secrets, ... }:
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
  networking = {
    nftables = {
      enable = true;
      checkRuleset = false;
      ruleset = ''
        table ip filter {
          flowtable f {
            hook ingress priority 0; 
            devices = { "${config.WAN}", "${config.LAN0}", "${config.LAN1}", "${config.LAN2}"};
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

            iifname "${config.WAN}" ct state { established, related } accept comment "Allow established traffic"
            iifname "${config.WAN}" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
            iifname "lo" accept comment "Accept everything from loopback interface"

            # Allow ports on config.WAN interface
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

            iifname { "br-cams" } oifname { "${config.WAN}" } udp dport ${ntp_port} accept comment "Allow NTP extenal access"
            iifname { "br-cams" } ip saddr 10.1.1.10 oifname { "${config.WAN}" } accept comment "Allow Frigate extenal access"
            iifname { "br-lan", "vl-mgmt",  "vl-guests"} oifname { "${config.WAN}" } accept comment "Allow trusted config.LAN to ${config.WAN} (external access)"
            iifname { "${config.WAN}" } oifname {  "br-lan", "vl-mgmt", "br-cams", "vl-home", "vl-guests" } ct state { established, related } accept comment "Allow established back to config.LANs"
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
            oifname "${config.WAN}" masquerade
          } 
        }
      '';
    };
  };
}
