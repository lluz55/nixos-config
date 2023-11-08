{ pkgs, master_user, lib, config, ... }:
let
  useDE = config.useDE;
in
with lib; {
  imports = [
    ./../de.nix
    ./hardware-configuration.nix
    #./virt.nix
    ./router.nix
  ];
  config = mkIf useDE
    {
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


    };
}
