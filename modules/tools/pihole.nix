{ pkgs, config, masterUser, ... }:
{
        virtualisation.oci-containers.containers = {
          pihole = {
            image = "pihole/pihole:latest";
            environment = {
              TZ = "America/Recife";
              WEBPASSWORD = "123pihole321";
              DNSMASQ_USER = "root";
            };
            extraOptions = [
              "--cap_add=NET_ADMIN"
              "--privileged"
              "--network=host"
            ];
            volumes = [
              "/home/lluz/.pihole:/etc/pihole"
              "/home/lluz/.pihole:/etc/dnsmasq.d"
            ];
          };

  };
#     version: "3.2"
  
# services:  
#   pihole:
#     container_name: pihole
#     image: pihole/pihole:latest
#     networks:
#       pihole_net:
#         ipv4_address: 192.168.31.215 
#     # For DHCP it is recommended to remove these ports and instead add: network_mode: "host"
#     ports:
#       - '56:53/tcp'
#       - '57:53/udp'
#       - '89:80/tcp'
#     environment:
#       - 'TZ=Africa/Casablanca'
#       - 'WEBPASSWORD: 123pihole321'
#       - DNSMASQ_USER=root
#     volumes:
#       - '${DOCKERCONFDIR}/pihole:/etc/pihole'
#       - '${DOCKERCONFDIR}/pihole:/etc/dnsmasq.d'
#     #   https://github.com/pi-hole/docker-pi-hole#note-on-capabilities
#     cap_add:
#       - NET_ADMIN # Required if you are using Pi-hole as your DHCP server, else not needed
#     restart: unless-stopped
}

