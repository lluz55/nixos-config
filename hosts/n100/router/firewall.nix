{ config, lib, ... }:
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
            iifname {"vl-guests", "vl-home"} meta l4proto { udp, tcp} th dport { 4244, 5222, 5223, 5228, 50318, 59234, 5242 } accept
            iifname {"vl-guests", "vl-home"} meta l4proto { udp, tcp} th dport 53 accept
            iifname "vl-guests" oifname { "vl-guests", "vl-home", "vl-mgmt", "br-cams", "br-lan"} drop comment "Block access to other networks"
            iifname "vl-home" oifname { "vl-guests", "vl-mgmt", "br-cams"} drop comment "Block access to other networks"
            iifname { "vl-home" } accept
            iifname { "vl-mgmt" } accept comment "Rede de manutencao confiavel — sem filtro por MAC"
            #iifname "vl-guests" oifname "${config.WAN}" accept
            
            # Limit guests network bandwidth
            meta iifname "vl-guests" limit rate over 500 kbytes/second drop

            # WiFi cameras (vl-cams) — allow only DHCP and DNS from the router
            # All other access is blocked here; only vl-mgmt can reach cameras via forward chain
            iifname "vl-cams" udp dport 67-68 accept comment "Allow DHCP for vl-cams"
            iifname "vl-cams" meta l4proto { udp, tcp } th dport 53 accept comment "Allow DNS for vl-cams"

            iifname "${config.WAN}" ct state { established, related } accept comment "Allow established traffic"
            iifname "${config.WAN}" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"

            # ICMPv6 na WAN — obrigatorio para IPv6 funcionar (RFC 4890).
            #
            # `icmp` acima e ICMPv4; sem as regras abaixo o Router Advertisement
            # do upstream cai no `policy drop` desta chain e o SLAAC nunca
            # completa: a WAN fica so com fe80:: e o host nao ganha GUA.
            # A regra `ct state established,related` NAO cobre isso — RA e
            # multicast nao solicitado e nao casa com conntrack.
            #
            # Isto NAO abre nada: continua sem qualquer regra aceitando
            # `ct state new` vindo da WAN. O hole punching do WebRTC (daemon
            # dl_home_control) passa pelo `established` acima, porque quem
            # inicia e o daemon — nenhuma porta precisa ser aberta.
            #
            # hoplimit 255 e exigencia do RFC 4861 §11: pacote NDP roteado de
            # fora do link chega com hoplimit menor e e descartado, o que
            # impede vizinho/roteador forjado remotamente.
            iifname "${config.WAN}" icmpv6 type { nd-neighbor-solicit, nd-neighbor-advert, nd-router-advert } ip6 hoplimit 255 counter accept comment "NDP/SLAAC — sem isto nao ha GUA na WAN"

            # packet-too-big nao e opcional: IPv6 nao fragmenta em transito, o
            # PMTUD depende inteiramente deste ICMPv6. Sem ele o sintoma e
            # conexao que estabelece e trava quando o pacote cresce.
            iifname "${config.WAN}" icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem } counter accept comment "ICMPv6 de erro (PMTUD)"

            iifname "${config.WAN}" icmpv6 type echo-request limit rate 10/second counter accept comment "ping6 com rate limit"

            iifname "lo" accept comment "Accept everything from loopback interface"

            # Audit logs for blocked attempts on WAN
            iifname "${config.WAN}" tcp flags & (fin|syn|rst|ack) == syn counter log prefix "NFT_INPUT_DROP: " drop
          }
          chain forward {
            type filter hook forward priority 0; policy drop;
            ip protocol { tcp, udp } ct state { established } flow add @f comment "Offload tcp/udp established traffic"
            ct status dnat accept comment "Allow NAT through interfaces"

            iifname { "vl-home" } oifname "${config.WAN}" ct state new accept
            iifname { "vl-mgmt" } oifname {"${config.WAN}", "br-cams", "br-lan", "vl-home"} ct state new accept 

            # vl-mgmt can reach vl-cams (WiFi cameras)
            iifname { "vl-mgmt" } oifname { "vl-cams" } ct state new accept comment "Allow mgmt to access WiFi cameras"

            # vl-cams: block all lateral access; only allow NTP outbound and established return
            iifname { "vl-cams" } oifname { "br-lan", "br-cams", "vl-home", "vl-guests", "vl-mgmt" } drop comment "Block vl-cams from all other networks"
            iifname { "vl-cams" } oifname { "${config.WAN}" } udp dport ${ntp_port} accept comment "Allow NTP external access for vl-cams"

            iifname { "br-cams" } oifname { "${config.WAN}" } udp dport ${ntp_port} accept comment "Allow NTP extenal access"
            iifname { "br-cams" } ip saddr { "10.1.1.10" , "10.1.1.9" , "10.1.1.8" } oifname { "${config.WAN}" } accept comment "Allow Frigate/Zigbee2mqtt extenal access"
            iifname { "br-lan", "vl-guests" } oifname { "${config.WAN}" } accept comment "Allow trusted to WAN interface (external access)"
            iifname { "${config.WAN}" } oifname {  "br-lan", "vl-mgmt", "br-cams", "vl-home", "vl-guests" } ct state { established, related } accept comment "Allow established back to other networks"
          }
        }

        table ip nat {
          chain prerouting {
            type nat hook prerouting priority dstnat; policy accept;

            iifname {"vl-mgmt", "br-lan", "vl-home"} tcp dport 8123 dnat 10.1.1.10 # Allow forwarding to Home Automation
             # iifname {"vl-mgmt", "br-lan", "vl-home"} tcp dport { 5000 } dnat 10.1.1.9 # Allow forwarding to Home Automation
            iifname {"vl-mgmt", "br-lan", "vl-home"} tcp dport { 5000 } dnat 10.1.1.1 # Allow forwarding to Home Automation
            iifname {"vl-mgmt", "br-lan", "vl-home"} tcp dport { 50001 } dnat 10.1.1.1 # Allow forwarding to Fix Frigate Image
            iifname {"vl-mgmt"} tcp dport { 5000, 1984 } dnat 10.1.1.9 # Allow forwarding to Frigate
            iifname {"vl-mgmt"} tcp dport 8080 dnat 10.1.1.8 # Allow forwarding to Zigbee2mqtt
            iifname {"vl-mgmt"} tcp dport 48899 dnat 10.1.1.14:8899 # Allow forwarding to CAM 14
            iifname {"vl-mgmt", "br-lan", "vl-home"} tcp dport 80 dnat 10.1.1.10 # Allow forwarding to Emulated Hue - HASS (Restricted to Internal)
            iifname {"vl-mgmt"} tcp dport 1880 dnat 10.1.1.10 # Allow forwarding to NodeRed
            iifname {"br-lan"} ip saddr 192.168.1.99 tcp dport 8080 dnat 10.1.1.8:8080 # Allow Twingate forwarding to Zigbee2mqtt
            iifname {"br-lan"} ip saddr 192.168.1.99 tcp dport 5000 dnat 10.1.1.9:5000 # Allow Twingate forwarding to Frigate
            iifname {"vl-home"} tcp dport 5000 dnat 10.1.1.9 # Allow forwarding to Frigate
            iifname {"vl-home"} tcp dport 8080 dnat 10.1.1.8 # Allow forwarding to Zigbee2mqtt

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
