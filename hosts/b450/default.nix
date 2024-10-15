{ unstable
, lib
, config
, zen-browser
  # , pkgs-aarch64
, ...
}:
let
  drive-flags = "format=raw,readonly=on";
in
with lib; {
  imports = [
    ./hardware-configuration.nix
  ];

  virt-tools.enable = true;
  gnome.enable = false;
  hyprland.enable = false;
  glances.enable = true;

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  boot = {
    kernelParams = [ "nvidia_drm.fbdev=1" ];
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;

    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
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

  hardware.opengl= {
    # extraPackages = with unstable; [ intel-media-driver ];

    enable = true;
    # driSupport = true;
    driSupport32Bit = true;
  };

  # TODO: change opengl to hardware.graphics.enable32Bit

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

  #sway.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Gaming
  programs = {
    steam = { 
      enable = true;
      gamescopeSession.enable = true;
    };
    gamemode.enable = true;
  };

  environment =
    #    let
    #      aarch64-linux-vm =
    #        unstable.writeScriptBin "run-nixos-vm-aarch64" ''
    #
    #            #!${unstable.runtimeShell} \
    #            ${unstable.qemu_full}/bin/qemu-system-aarch64 \
    #            -machine virt \
    #            -cpu cortex-a57 \
    #            -m 2G \
    #            -nographic \
    #            -drive if=pflash,file=${pkgs-aarch64.OVMF.fd}/AAVMF/QEMU_EFI-pflash.raw,${drive-flags} \
    #            -drive file=/home/lluz/Downloads/nixos-aarch64-linux.iso,${drive-flags}
    #            '';
    #    in
    {
      sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/lluz/.steam/root/compatibilitytools.d";
      };
      systemPackages = with unstable; [
        # Gaming
        mangohud
        protonup

        # Shells
        nushell
        
        # Remote
        twingate
        #x2goclient
        #turbovnc
        #remmina

        # Networking tools
        nmap

        # Dev tools
        lazygit
        rustup

        # Editors
        neovim
        vscode

        # 3D tools
        blender

        font-awesome_4

        # Nvidia drivers
        nvidia-vaapi-driver

        # Browsers
        vivaldi
        zen-browser

        # Others
        cosmic-applets
        xboxdrv # xbox controller drivers
      ];
    };
}
