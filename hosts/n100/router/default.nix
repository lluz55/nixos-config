{ ... }:
{
  imports = [
    ./options.nix
    ./networking.nix
    ./firewall.nix
    ./dnsmasq.nix
  ];

  boot = {
    kernel = {
      sysctl = {
        "net.ipv4.conf.all.forwarding" = true;
        "net.ipv6.conf.all.forwarding" = true;
        "net.ipv4.ip_forward" = 1;
      };
    };
  };
  services.irqbalance.enable = true;
  services.resolved.enable = false;
}
