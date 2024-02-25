{
  unstable,
  lib,
  config,
  ...
}:
with lib; {
  imports = [
    ./hardware-configuration.nix
  ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;

    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:0:1:0";
      sync.enable = true; # Disable NVIDIA GPU
      #offload.enable = true;
    };
    powerManagement = {
      enable = true;
      #finegrained = true;
    };
  };

  virt-tools.enable = true;
  gnome.enable = true;
  hyprland.enable = true;
  
  i18n = {
    supportedLocales = lib.mkDefault [
      "en_US.UTF-8/UTF-8"
      "pt_BR.UTF-8/UTF-8"
    ];
  };

  hardware.opengl = {
    extraPackages = with unstable; [intel-media-driver];
    # extraPackages32 = with unstable.pkgsi686Linux; [nvidia-vaapi-driver intel-media-driver];

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
    xserver.videoDrivers = ["nvidia"];
    logind.extraConfig = ''
      IeAction=suspend
      I#dleActionSec=30min
    '';
  };

  boot = {
    kernelPackages = unstable.linuxPackages_latest;
    loader = {
      grub = {
        enable = true;
        devices = ["/dev/sda"];
        useOSProber = true;
        configurationLimit = 4;
        theme = unstable.stdenv.mkDerivation {
          pname = "distro-grub-themes";
          version = "3.1";
          src = unstable.fetchFromGitHub {
            owner = "AdisonCavani";
            repo = "distro-grub-themes";
            rev = "v3.1";
            hash = "sha256-ZcoGbbOMDDwjLhsvs77C7G7vINQnprdfI37a9ccrmPs=";
          };
          installPhase = "cp -r customize/nixos $out";
        };
      };
      timeout = 3;
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

  environment = {
    systemPackages = with unstable; [
      vscode
      nmap
      remmina
      x2goclient
      turbovnc
      lazygit
      vivaldi
      #rust-analyzer
      #neovim
      rustup
    ];
  };
}
