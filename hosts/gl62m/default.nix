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

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;

    # Usa driver estável pré-compilado para evitar build em cada atualização
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    nvidiaSettings = true;

    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:0:1:0";
      sync.enable = true; # Disable NVIDIA GPU
      #offload = {
      #  enable = true;
      #  enableOffloadCmd = true;
      #};
    };
    powerManagement = {
      enable = true;
      #finegrained = true;
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
    openssh = {
      enable = true;
    };
    xserver.videoDrivers = [ "nvidia" ];
  };

  boot = {
    kernelPackages = unstable.linuxPackages;
    loader = {
      efi.canTouchEfiVariables = true;
      timeout = 2;
      systemd-boot.enable = true;
    };
  };

  hardware.acpilight.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.systemPackages = with unstable; [
    (unstable.writeShellScriptBin "nof" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '')
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
    rustup
    font-awesome_4
    nvidia-vaapi-driver
    qutebrowser
    wineWow64Packages.stableFull
    cosmic-applets
    wl-clipboard
    dust
    vivaldi
  ];
}
