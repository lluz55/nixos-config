{
  unstable,
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  battery-up-pkg = pkgs.callPackage ../../pkgs/battery-up/package.nix {};
  bestfin-pkg = pkgs.callPackage ../../pkgs/bestfin/package.nix {};
  codex-openrouter-pkg = pkgs.callPackage ../../pkgs/codex-openrouter/package.nix {codex = unstable.codex;};
  kon-pkg = pkgs.callPackage ../../pkgs/kon/package.nix {};
  kon-openrouter-pkg = pkgs.callPackage ../../pkgs/kon-openrouter/package.nix {kon = kon-pkg;};
  kilocode-pkg = pkgs.callPackage ../../pkgs/kilocode/package.nix {};
  hound-mcp-pkg = pkgs.callPackage ../../pkgs/hound-mcp/package.nix {};
  dsh-pkg = pkgs.callPackage ../../pkgs/dsh/package.nix {};
  donsetch-pkg = pkgs.callPackage ../../pkgs/donsetch/package.nix {};
  codegraph-pkg = pkgs.callPackage ../../pkgs/codegraph/package.nix {};
  hermes-agent-pkg = pkgs.callPackage ../../pkgs/hermes-agent/package.nix {};
in
  with lib; {
    imports = [
      ./hardware-configuration.nix
      ../../pkgs/battery-up/module.nix
      ../../pkgs/bestfin/module.nix
      ../../pkgs/9router/module.nix
      ../../pkgs/pi-web/module.nix
      inputs.searxng-mpc.nixosModules.default
    ];

    profiles.desktop.enable = true;

    programs.bestfin = {
      enable = true;
      package = bestfin-pkg;
    };

    programs.appimage = {
      enable = true;
      binfmt = true;
    };
    profiles.rtl88x2bu.enable = true;
    virt-tools.enable = false;

    sops.secrets = lib.mkForce {
      "passwords/lluz" = {
        neededForUsers = true;
      };
      "nix_tokens/github.com" = {};
      "opencode/api_key" = {owner = "lluz";};
    };
    twingate.enable = lib.mkForce false;

    networking = {
      hostName = "s14";
      networkmanager = {
        enable = true;
        wifi.powersave = false;
      };
      firewall = {
        allowedTCPPorts = [18081 18082 8584]; # 8584: PI WEB (services.pi-web)
        allowedUDPPorts = [18082 37020];
      };
    };

    # Impressora/scanner Epson L395 (CUPS + escpr, SANE + epsonscan2).
    profiles.printing.enable = true;

    # render: nós de GPU/NPU; lp e scanner: impressão e digitalização.
    users.users.lluz.extraGroups = ["render" "lp" "scanner"];

    zramSwap = {
      enable = true;
      algorithm = "zstd"; # Optimized compression algorithm
    };

    hardware.graphics = {
      enable32Bit = true;
      extraPackages = with unstable; [
        intel-media-driver
        vpl-gpu-rt
        intel-compute-runtime
      ];
    };

    powerManagement.enable = true;

    services = {
      twingate.enable = lib.mkForce true;
      pulseaudio.enable = false;
      flatpak.enable = true;

      battery-up = {
        enable = true;
        # package default = binário do release (pkgs/battery-up/package.nix);
        # override explícito mantido por clareza.
        package = battery-up-pkg;
      };

      "9router" = {
        enable = true;
        headroom.enable = true;
      };

      # PI WEB — UI web para sessões persistentes do Pi Coding Agent.
      # Bind em 0.0.0.0:8584 (porta liberada no firewall abaixo) para acesso
      # direto na LAN/rede confiável. Sem autenticação nativa — não expor essa
      # porta diretamente à internet sem VPN/reverse-proxy autenticado na frente.
      pi-web = {
        enable = true;
        host = "0.0.0.0";
        port = 8584;
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
        timeout = 2;
        systemd-boot.enable = true;
        systemd-boot.configurationLimit = 5;
      };
      # Load the modern xe driver for Intel Arc graphics (Arrow Lake)
      initrd.kernelModules = ["xe"];
      kernelParams = [
        "xe.force_probe=7d51"
        "i915.force_probe=!7d51"
      ];
      extraModprobeConfig = ''
        options iwlwifi power_save=0
        options iwlmvm power_scheme=1
      '';
    };

    systemd.services.disable-wifi-d3cold = {
      description = "Desabilitar D3cold para placa Wi-Fi Realtek (rtw89_8852be)";
      wantedBy = ["multi-user.target"];
      after = ["systemd-udevd.service"];
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
      wantedBy = ["post-resume.target"];
      after = ["post-resume.target"];
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

    environment = {
      sessionVariables = {
        LIBVA_DRIVER_NAME = "iHD";
        QTWEBENGINE_CHROMIUM_FLAGS = "--enable-unsafe-webgpu --use-angle=vulkan --enable-features=Vulkan,VulkanFromANGLE";
      };
      systemPackages = with unstable; [
        wineWowPackages.stableFull
        battery-up-pkg
        intel-npu-driver
        opencode
        pi-coding-agent
        codex-openrouter-pkg
        kon-pkg
        kon-openrouter-pkg
        kilocode-pkg
        hound-mcp-pkg
        dsh-pkg
        donsetch-pkg
        codegraph-pkg
        hermes-agent-pkg
        config.services.pi-web.package
        inputs.searxng-mpc.packages.${pkgs.system}.searxng-instance
        inputs.searxng-mpc.packages.${pkgs.system}.all-in-one
      ];
    };
  }
