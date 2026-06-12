{ unstable
, lib
, config
  #, pkgs-aarch64
, self
, ...
}:
let
  drive-flags = "format=raw,readonly=on";
in
with lib; {
  imports = [
    ./hardware-configuration.nix
  ];

  virt-tools.enable = false;
  gnome.enable = false;
  hyprland.enable = false;
  arduino.enable = false;

  networking.networkmanager.enable = true;

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # Ensure user lluz has access to GPU and NPU render nodes
  users.users.lluz.extraGroups = [ "render" ];

  zramSwap = {
    enable = true;
    algorithm = "zstd"; # Optimized compression algorithm
  };

  i18n = {
    supportedLocales = lib.mkDefault [
      "en_US.UTF-8/UTF-8"
      "pt_BR.UTF-8/UTF-8"
    ];
  };

  hardware.graphics = {
    extraPackages = with unstable; [
      intel-media-driver
      vpl-gpu-rt
      intel-compute-runtime
    ];
    enable = true;
    enable32Bit = true;
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  services = {
    pulseaudio.enable = false;
    flatpak.enable = true;
    openssh = {
      enable = true;
    };
    
    # Power and thermal management optimized for Intel Core Ultra (Arrow Lake)
    power-profiles-daemon.enable = false;
    auto-cpufreq.enable = true;
    thermald.enable = true;
  };

  boot = {
    kernelPackages = unstable.linuxPackages;
    loader = {
      efi.canTouchEfiVariables = true;
      # system-boot.enable = true;
      timeout = 2;
      systemd-boot.enable = true;
    };
    # Load the modern xe driver for Intel Arc graphics (Arrow Lake)
    initrd.kernelModules = [ "xe" ];
    kernelParams = [
      "xe.force_probe=7d51"
      "i915.force_probe=!7d51"
    ];
  };

  hardware.acpilight.enable = true;

  # TP-Link Archer T3U (RTL8812BU) driver
  boot.kernelModules = [ "rtw_8812bu" ];
  hardware.firmware = with unstable; [ linux-firmware ];

  #sway.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment = {
    sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };
    systemPackages = with unstable; [
      vscode
      nmap
      remmina
      x2goclient
      turbovnc
      lazygit
      (vivaldi.override {
        proprietaryCodecs = true;
      })
      vivaldi-ffmpeg-codecs
      #neovim
      rustup

      #blender

      font-awesome_4

      qutebrowser
      wineWow64Packages.stableFull
      cosmic-applets
      wl-clipboard
      dust
      vivaldi
      
      # Intel NPU driver for AI workloads (OpenVINO, Level Zero)
      intel-npu-driver
    ];
  };
}
