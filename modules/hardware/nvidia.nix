{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hardware.nvidia.custom;
in
{
  options.hardware.nvidia.custom = {
    enable = mkEnableOption "Custom NVIDIA driver configuration";
    
    powerManagement = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable NVIDIA power management (experimental but required for modern suspend/hibernate)";
      };
    };

    prime = {
      enable = mkEnableOption "NVIDIA Prime offloading/sync";
      intelBusId = mkOption {
        type = types.str;
        default = "";
        description = "Intel GPU PCI Bus ID";
      };
      nvidiaBusId = mkOption {
        type = types.str;
        default = "";
        description = "NVIDIA GPU PCI Bus ID";
      };
      sync = mkOption {
        type = types.bool;
        default = false;
        description = "Enable NVIDIA Prime Sync (forces GPU always on, avoids screen tearing)";
      };
    };
  };

  config = mkIf cfg.enable {
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = true;
      open = mkDefault false;
      nvidiaSettings = true;
      package = mkDefault config.boot.kernelPackages.nvidiaPackages.latest;
      
      powerManagement.enable = cfg.powerManagement.enable;

      prime = mkIf cfg.prime.enable {
        inherit (cfg.prime) intelBusId nvidiaBusId;
        sync.enable = cfg.prime.sync;
      };
    };
  };
}
