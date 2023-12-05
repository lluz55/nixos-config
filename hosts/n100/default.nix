{ pkgs, lib, unstable, ... }:

with lib;{
  imports = [
    ./../../modules
    ./hardware-configuration.nix
    ./virt.nix
    ./router.nix
    ./frigate.nix
  ];

  gnome.enable = true;

  services.tailscale.enable = true;

  services.openssh = {
    enable = true;
    passwordAuthentication = true;
  };
  environment.systemPackages = with unstable; [
    tailscale
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };
  };

  programs.light.enable = true;

}
