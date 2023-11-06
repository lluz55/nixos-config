{ pkgs, var, config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    #./virt.nix
    ./router.nix
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
