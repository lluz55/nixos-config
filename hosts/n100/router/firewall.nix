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
        table inet filter {
          set authorized_home {
            typeof ether saddr
            flags constant
            elements = {
              ${config.macs.rn10c},
              ${config.macs.poco},
              ${config.macs.gl62m},
              ${config.macs.b450},
              ${config.macs.honor},
              ${config.macs.mibox2},
              ${config.macs.tabs5e},
              ${config.macs.a55},
            }
          }
          set authorized_mgmt {
            typeof ether saddr
            flags constant
            elements = {
              ${config.macs.poco},
              ${config.macs.gl62m},
              ${config.macs.b450},
              ${config.macs.a55},
            }
          }
          limit slow {
            rate over 1 mbytes/second 
          }
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
            iifname { "vl-home" } ether saddr @authorized_home accept
            iifname { "vl-mgmt" } ether saddr @authorized_mgmt accept 
            #iifname "vl-guests" oifname "${config.WAN}" accept
            
            # Limit guests network bandwidth
            meta iifname "vl-guests" limit rate over 500 kbytes/second drop

            iifname "${config.WAN}" ct state { established, related } accept comment "Allow established traffic"
            iifname "${config.WAN}" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
            iifname "lo" accept comment "Accept everything from loopback interface"
          }
          chain forward {
            type filter hook forward priority 0; policy drop;
            ip protocol { tcp, udp } ct state { established } flow add @f comment "Offload tcp/udp established traffic"
            ct status dnat accept comment "Allow NAT through interfaces"

            iifname { "vl-home" } ether saddr @authorized_home oifname "${config.WAN}" ct state new accept  
            iifname { "vl-mgmt" } ether saddr @authorized_mgmt oifname {"${config.WAN}", "br-cams", "br-lan", "vl-home"} ct state new accept 
            iifname { "br-cams" } oifname { "${config.WAN}" } udp dport ${ntp_port} accept comment "Allow NTP extenal access"
            iifname { "br-cams" } ip saddr { "10.1.1.10" , "10.1.1.9" } oifname { "${config.WAN}" } accept comment "Allow Frigate extenal access"
            iifname { "br-lan", "vl-guests" } oifname { "${config.WAN}" } accept comment "Allow trusted to WAN interface (external access)"
            iifname { "${config.WAN}" } oifname {  "br-lan", "vl-mgmt", "br-cams", "vl-home", "vl-guests" } ct state { established, related } accept comment "Allow established back to other networks"
          }
        }

        table ip nat {
          chain prerouting {
            type nat hook prerouting priority dstnat; policy accept;

            iifname {"vl-mgmt", "br-lan", "vl-home"} tcp dport { 8123, 8080 } dnat 10.1.1.10 # Allow forwarding to Home Automation
            iifname {"vl-mgmt", "br-lan", "vl-home"} tcp dport { 5000 } dnat 10.1.1.9 # Allow forwarding to Home Automation
            iifname {"vl-mgmt"} tcp dport 5000 dnat 10.1.1.9 # Allow forwarding to Frigate
            iifname {"vl-mgmt"} tcp dport 8080 dnat 10.1.1.10 # Allow forwarding to Zigbee2mqtt
            tcp dport 80 dnat 10.1.1.10 # Allow forwarding to Emulated Hue - HASS
            iifname {"vl-mgmt"} tcp dport 1880 dnat 10.1.1.10 # Allow forwarding to NodeRed
            iifname {"br-lan"} ip saddr 192.168.1.99 tcp dport 8080 dnat 10.1.1.10:8080 # Allow Twingate forwarding to Zigbee2mqtt
            iifname {"br-lan"} ip saddr 192.168.1.99 tcp dport 5000 dnat 10.1.1.9:5000 # Allow Twingate forwarding to Frigate
            iifname {"vl-home"} tcp dport 5000 dnat 10.1.1.9 # Allow forwarding to Frigate
            iifname {"vl-home"} tcp dport 8080 dnat 10.1.1.10 # Allow forwarding to Zigbee2mqtt

            iifname {"vl-mgmt"} tcp dport 60014 dnat 10.1.1.14:34567 # Camera 14 XMeye config
            iifname {"vl-mgmt"} tcp dport 60013 dnat 10.1.1.13:34567 # Camera 13 XMeye config
            iifname {"vl-mgmt"} tcp dport 60012 dnat 10.1.1.12:34567 # Camera 12 XMeye config
            iifname {"vl-mgmt"} tcp dport 60011 dnat 10.1.1.11:80 # Camera 11 XMeye config
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
