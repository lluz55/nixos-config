{ unstable
, lib
, config
  #, pkgs-aarch64
, zen-browser
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

  virt-tools.enable = false;
  gnome.enable = true;
  hyprland.enable = false;
  arduino.enable = false;

   services.desktopManager.cosmic.enable = false;
   services.displayManager.cosmic-greeter.enable = false;

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
    extraPackages = with unstable; [  ];
    # extraPackages32 = with unstable.pkgsi686Linux; [nvidia-vaapi-driver intel-media-driver];

    enable = true;
    driSupport32Bit = true;
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  services = {
    flatpak.enable = true;
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
      };
    };
    xserver.videoDrivers = [ "amd" ];
    logind.extraConfig = ''
      IeAction=suspend
      I#dleActionSec=30min
    '';
  };

  boot = {
    kernelPackages = unstable.linuxPackages_latest;
    loader = {
        efi.canTouchEfiVariables = true;
        # system-boot.enable = true;
        timeout = 2;
        systemd-boot.enable = true;
        # grub = {
        #   enable = true;
        #   devices = ["/dev/sda"];
        #    # devices = [ "/dev/sda" ];
        #    # device = "/dev/sdb";
        #    useOSProber = true;
        #    configurationLimit = 4;
        #    efiSupport = true;
        #    #theme = unstable.stdenv.mkDerivation {
        #    #  pname = "distro-grub-themes";
        #    #  version = "3.1";
        #    #  src = unstable.fetchFromGitHub {
        #    #    owner = "AdisonCavani";
        #    #    repo = "distro-grub-themes";
        #    #    rev = "v3.1";
        #    #    hash = "sha256-ZcoGbbOMDDwjLhsvs77C7G7vINQnprdfI37a9ccrmPs=";
        #    #  };
        #    #  installPhase = "cp -r customize/nixos $out";
        #    #};
        #  };
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

          wineWowPackages.stableFull
          cosmic-applets
          dust
          zen-browser
          vivaldi
        ];
    };
}
