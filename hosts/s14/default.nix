{ unstable
, lib
, config
, pkgs
  #, pkgs-aarch64
, self
, inputs
, waydroidsu
, ...
}:
let
  drive-flags = "format=raw,readonly=on";
  battery-up-pkg = inputs.battery_up.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
with lib; {
  imports = [
    ./hardware-configuration.nix
    inputs.battery_up.nixosModules.default
  ];

  virt-tools.enable = false;
  virtualisation.waydroid.enable = true;
  virtualisation.waydroid.package = unstable.waydroid-nftables;
  gnome.enable = false;
  hyprland.enable = false;
  arduino.enable = false;

  sops.secrets = lib.mkForce { };
  sops.age.keyFile = lib.mkForce "/etc/ssh/ssh_host_ed25519_key";
  twingate.enable = lib.mkForce false;

  networking = {
    hostName = "s14";
    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };
  };

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

  powerManagement.enable = true;

  services = {
    twingate.enable = lib.mkForce true;
    pulseaudio.enable = false;
    flatpak.enable = true;
    openssh = {
      enable = true;
    };

    battery-up = {
      enable = true;
      package = battery-up-pkg;
    };
    
    # Power and thermal management optimized for Intel Core Ultra (Arrow Lake)
    # power-profiles-daemon is required by COSMIC desktop for power management integration
    # system76-power is for System76 hardware only — not applicable here
    power-profiles-daemon.enable = true;
    # auto-cpufreq conflicts with power-profiles-daemon (both manage CPU freq scaling)
    auto-cpufreq.enable = false;
    thermald.enable = true;
  };

  boot = {
    kernelPackages = unstable.linuxPackages;
    loader = {
      efi.canTouchEfiVariables = true;
      # system-boot.enable = true;
      timeout = 2;
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5;
    };
    # Load the modern xe driver for Intel Arc graphics (Arrow Lake)
    initrd.kernelModules = [ "xe" ];
    kernelParams = [
      "xe.force_probe=7d51"
      "i915.force_probe=!7d51"
    ];
    extraModprobeConfig = ''
      options iwlwifi power_save=0
      options iwlmvm power_scheme=1
    '';
  };

  hardware.acpilight.enable = true;

  systemd.services.disable-wifi-d3cold = {
    description = "Desabilitar D3cold para placa Wi-Fi Realtek (rtw89_8852be)";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udevd.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "disable-d3cold" ''
        for dev in /sys/bus/pci/drivers/rtw89_8852be/0000:*; do
          [ -d "$dev" ] && echo 0 > "$dev/d3cold_allowed" || true
        done
        exit 0
      '';
    };
  };

  systemd.services.wifi-reset-after-resume = {
    description = "Resetar WiFi Realtek após retorno da suspensão";
    wantedBy = [ "post-resume.target" ];
    after = [ "post-resume.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;
      ExecStart = pkgs.writeShellScript "wifi-reset" ''
        ${unstable.kmod}/bin/rmmod rtw89_8852be rtw89_8852b rtw89_pci rtw89_core 2>/dev/null || true
        ${pkgs.coreutils}/bin/sleep 1
        ${unstable.kmod}/bin/modprobe rtw89_8852be
        ${pkgs.coreutils}/bin/sleep 2
        ${pkgs.systemd}/bin/systemctl restart NetworkManager
        ${pkgs.bash}/bin/bash -c 'for dev in /sys/bus/pci/drivers/rtw89_8852be/0000:*; do [ -d "$dev" ] && echo 0 > "$dev/d3cold_allowed"; done'
      '';
    };
  };

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
      QTWEBENGINE_CHROMIUM_FLAGS = "--enable-unsafe-webgpu --use-angle=vulkan --enable-features=Vulkan,VulkanFromANGLE";
    };
    systemPackages = with unstable; [
      twingate
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
      battery-up-pkg
      wl-clipboard
      dust
      vivaldi
      brave
      
      # Intel NPU driver for AI workloads (OpenVINO, Level Zero)
      intel-npu-driver
      waydroid-helper
      waydroidsu
    ];
  };
}
