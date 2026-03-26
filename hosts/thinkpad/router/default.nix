{ lib, ... }:
with lib; {
  imports = [
    ./options.nix
    ./networking.nix
    ./hostapd.nix
    ./dnsmasq.nix
    ./firewall.nix
    ./checks.nix
  ];
}
