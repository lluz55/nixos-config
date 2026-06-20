{ unstable
, config
, ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];
  # Twingate Server 2 connector
  virtualisation.oci-containers.containers."twingate-server" = {
    image = "twingate/connector:1.78";
    environment = {
      TWINGATE_LABEL_HOSTNAME = "`hostname`";
    };
    extraOptions = [
      "--dns=8.8.8.8,1.1.1.1"
      "--network=host"
      "--env-file=${config.sops.secrets."twingate_2.env".path}"
    ];
  };

  virtualisation.oci-containers.containers."searxng" = {
    image = "searxng/searxng:latest";
    environment = {
      TWINGATE_LABEL_HOSTNAME = "`hostname`";
      ENABLE_RAG_WEB_SEARCH = "True";
      RAG_WEB_SEARCH_ENGINE = "searxng";
      RAG_WEB_SEARCH_RESULT_COUNT = "3";
      RAG_WEB_SEARCH_CONCURRENT_REQUESTS = "10";
      SEARXNG_QUERY_URL = "http://searxng:8080/search?q=<query>";
    };
    volumes = [
      "/home/lluz/.config/searxng/:/etc/searxng"
    ];
    extraOptions = [
      "--network=host"
    ];
  };
  users.users.lluz = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "podman" ]; # Add "podman" group
    subGidRanges = [{ startGid = 100000; count = 65536; }];
    subUidRanges = [{ startUid = 100000; count = 65536; }];
    # ... other user settings ...
  };
  virtualisation = {
    containers.enable = true;
    containers.storage.settings = {
      storage = {
        driver = "overlay";
        runroot = "/run/containers/storage";
        graphroot = "/var/lib/containers/storage";
        rootless_storage_path = "/tmp/containers-$USER";
        options.overlay.mountopt = "nodev,metacopy=on";
      };
    };

    oci-containers.backend = "podman";
    podman = {
      enable = true;
      dockerCompat = true;
      # extraPackages = [ pkgs.zfs ]; # Required if the host is running ZFS
    };
  };
  hardware.nvidia-container-toolkit.enable = true;

  environment.extraInit = ''
    if [ -z "$DOCKER_HOST" -a -n "$XDG_RUNTIME_DIR" ]; then
      export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
    fi
  '';

  # My services
  profiles.desktop.enable = true;
  profiles.rtl88x2bu.enable = true;
  virt-tools.enable = true;
  glances.enable = true;

  boot = {
    kernelParams = [ "nvidia_drm.fbdev=1" ];
    extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];
    extraModprobeConfig = ''
      options bluetooth disable_ertm=Y
    '';
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 1420 4008 4009 3000 3001 5137 11434 8080 ];

  };

  hardware.nvidia.custom.enable = true;

  networking.interfaces.eno1.wakeOnLan = {
    enable = true;
  };

  zramSwap = {
    enable = true;
    algorithm = "lz4";
  };

  services = {
    logind.settings.Login = {
      IeAction = "suspend";
      IdleActionSec = "30min";
    };
  };

  boot = {
    kernelPackages = unstable.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 2;
    };
  };



  # Gaming
  programs = {
    steam = {
      enable = true;
      gamescopeSession.enable = true;
    };
    gamemode.enable = true;
  };

  # Enable xbox controller
  hardware.xpadneo.enable = true;
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        Privacy = "device";
        JustWorksRepairing = "always";
        Class = "0x000100";
        FastConnectable = true;
      };
    };
  };

  environment =
    {
      sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/lluz/.steam/root/compatibilitytools.d";
        COSMIC_DATA_CONTROL_ENABLED = 1;
      };
      systemPackages = with unstable; [
        docker-compose
        # Gaming
        mangohud
        protonup-ng

        # Shells
        nushell

        # Dev tools
        devenv
        dysk

        # 3D tools
        blender

        # Nvidia drivers
        nvidia-vaapi-driver

        # AI
        lmstudio
        nvitop
        opencode
        appimage-run

        davinci-resolve
      ];
    };
}
