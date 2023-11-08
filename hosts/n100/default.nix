{ pkgs, lib, ... }:

with lib;{
  imports = [
    ./../../modules
    ./hardware-configuration.nix
    #./virt.nix
    ./router.nix
  ];

  gnome.enable = true;

  users.users.lluz.isNormalUser = false;
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
