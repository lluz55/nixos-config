{ unstable
, lib
, config
  #, pkgs-aarch64
, self
, ...
}:
let
  pkgs-x86_64 = import unstable { system = "x86_64-linux"; };
  # pkgs-aarch64 = import unstable { system = "aarch64-linux"; };
  drive-flags = "format=raw,readonly=on";
in
with lib; {
  imports = [
    ./hardware-configuration.nix
  ];

  virt-tools.enable = true;
  gnome.enable = true;
  hyprland.enable = true;
  arduino.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;

    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
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


  i18n = {
    supportedLocales = lib.mkDefault [
      "en_US.UTF-8/UTF-8"
      "pt_BR.UTF-8/UTF-8"
    ];
  };

  hardware.opengl = {
    extraPackages = with unstable; [ intel-media-driver ];
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
    xserver.videoDrivers = [ "nvidia" ];
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
        devices = [ "/dev/sda" ];
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
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment =
    #let
    #  aarch64-linux-vm =
    #    unstable.writeScriptBin "run-nixos-vm-aarch64" ''

    #        #!${unstable.runtimeShell} \
    #        ${unstable.qemu_full}/bin/qemu-system-aarch64 \
    #        -machine virt \
    #        -cpu cortex-a57 \
    #        -m 2G \
    #        -nographic \
    #        -drive if=pflash,file=${pkgs-aarch64.OVMF.fd}/AAVMF/QEMU_EFI-pflash.raw,${drive-flags} \
    #        -drive file=${self.packages."x86_64-linux".aarch64-linux-iso}/iso/nixos.iso,${drive-flags}
    #        '';
    #in
    {
      systemPackages = with unstable;
        [
          # aarch64-linux-vm
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
          vivaldi
          #neovim
          rustup

          blender

          font-awesome_4
          nvidia-vaapi-driver

          wineWowPackages.stableFull
        ];
    };
}
