{ unstable
, lib
, config
, ...
}:
with lib; {
  imports = [
    ./hardware-configuration.nix
  ];

  profiles.desktop.enable = true;
  profiles.rtl88x2bu.enable = true;
  virt-tools.enable = false;

  networking.networkmanager.enable = true;

  hardware.nvidia.custom = {
    enable = true;
    powerManagement.enable = true;
    prime = {
      enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:0:1:0";
      sync = true;
    };
  };



  zramSwap = {
    enable = true;
    algorithm = "lz4";
  };

  hardware.graphics = {
    extraPackages = with unstable; [ intel-media-driver ];
  };

  services = {
    pulseaudio.enable = false;
    flatpak.enable = true;
  };

  boot = {
    kernelPackages = unstable.linuxPackages;
    loader = {
      efi.canTouchEfiVariables = true;
      timeout = 2;
      systemd-boot.enable = true;
    };
  };



  environment.systemPackages = with unstable; [
    (unstable.writeShellScriptBin "nof" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '')
    nvidia-vaapi-driver
    wineWow64Packages.stableFull
  ];
}
