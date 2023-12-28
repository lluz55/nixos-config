{ ... }:
{
  imports = [
    ./options.nix
    ./base.nix
    ./networking.nix
    ./firewall.nix
    ./dnsmasq.nix
  ];
}
