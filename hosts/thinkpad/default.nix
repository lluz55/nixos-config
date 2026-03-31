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
    ./router
    ./router-specialisation.nix
  ];
  services.avahi.enable = false;

  sops.secrets = lib.mkForce { };
  sops.age.keyFile = lib.mkForce "/etc/ssh/ssh_host_ed25519_key";
  twingate.enable = lib.mkForce false;

  cameraRouter.enable = false;

  virt-tools.enable = false;
  gnome.enable = false;
  hyprland.enable = false;
  arduino.enable = false;

   services.desktopManager.cosmic.enable = true;
   services.displayManager.cosmic-greeter.enable = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };


  # Adicionar seu usuário ao grupo adbusers (substitua 'seu-usuario' pelo seu nome de usuário real)
  users.users.lluz.extraGroups = [ "adbusers" ];

  i18n = {
    supportedLocales = lib.mkDefault [
      "en_US.UTF-8/UTF-8"
      "pt_BR.UTF-8/UTF-8"
    ];
  };

  # systemd.network.networks."10-lan" = {
  #   matchConfig.Name = "enp2s0";
  #   networkConfig.DHCP = "ipv4";
  # };

  hardware.graphics= {
    # extraPackages32 = with unstable.pkgsi686Linux; [nvidia-vaapi-driver intel-media-driver];

    enable = true;
    enable32Bit = true;
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  services = {
    twingate.enable = lib.mkForce true;
    power-profiles-daemon.enable = false;
    auto-cpufreq.enable = true;
    thermald.enable = true;
    flatpak.enable = true;
    openssh = {
      enable = true;
    };
    xserver.videoDrivers = [ "amd" ];
    logind.settings.Login = {
      IeAction= "suspend";
      IdleActionSec= "30min";
    };
  };

  boot = {
    kernelPackages = unstable.linuxPackages_latest;
    kernelModules = [ "xt_LOG" "xt_conntrack" "xt_state" "xt_nat" "iptable_filter" "iptable_nat" ];
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
        #    #    op = "distro-grub-themes";
        #    #    rev = "v3.1";
        #    #    hash = "sha256-ZcoGbbOMDDwjLhsvs77C7G7vINQnprdfI37a9ccrmPs=";
        #    #  };
        #    #  installPhase = "cp -r customize/nixos $out";
        #    #};
        #  };
      };
  };

  # TP-Link Archer T3U (RTL8812BU) driver
  boot.kernelModules = [ "rtw_8812bu" ];
  hardware.firmware = with unstable; [ linux-firmware ];

  #programs.direnv = {
  #  enable = true;
  #  nix-direnv = {
  #    enable = true;
  #    package = unstable.nix-direnv;
  #  };
  #};

  #sway.enable = true;

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
          twingate
          vscode
          nmap
          # remmina
          # x2goclient
          # turbovnc
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
          # wineWowPackages.stableFull
          cosmic-applets
          dust
          vivaldi
          brave
        ];
    };
}
