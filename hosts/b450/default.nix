{ unstable
, lib
, config
, ...
}:
with lib; {
  imports = [
    ./hardware-configuration.nix
  ];

  virt-tools.enable = true;
  gnome.enable = true;
  hyprland.enable = true;
  glances.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;

    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  networking.interfaces.eno1.wakeOnLan = {
    enable = true;
  };

  zramSwap = {
    enable = true;
    algorithm = "lz4";
  };

  i18n = {
    supportedLocales = lib.mkDefault [
      "en_US.UTF-8/UTF-8"
      "pt_BR.UTF-8/UTF-8"
    ];
  };

  hardware.opengl = {
    # extraPackages = with unstable; [ intel-media-driver ];

    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
      };
    };
    xserver.videoDrivers = [ "nvidia" ];
    logind.extraConfig = ''
      IeAction=suspend
      I#dleActionSec=30min
    '';
  };

  boot = {
    kernelPackages = unstable.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 2;
    };
  };

  programs.light.enable = true;
  #programs.direnv = {
  #  enable = true;
  #  nix-direnv = {
  #    enable = true;
  #    package = unstable.nix-direnv;
  #  };
  #};

  #sway.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment = {
    systemPackages = with unstable; [
      vscode
      nmap
      remmina
      x2goclient
      turbovnc
      lazygit
      vivaldi
      neovim
      rustup

      blender

      font-awesome_4
      nvidia-vaapi-driver
    ];
  };
}
