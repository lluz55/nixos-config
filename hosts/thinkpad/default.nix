{ unstable
, lib
, config
, ...
}:
with lib; {
  imports = [
    ./hardware-configuration.nix
    ./router
    ./router-specialisation.nix
  ];
  services.avahi.enable = false;

  sops.secrets = lib.mkForce {
    "passwords/lluz" = {
      neededForUsers = true;
    };
  };
  twingate.enable = lib.mkForce false;

  cameraRouter.enable = false;

  profiles.desktop.enable = true;
  profiles.rtl88x2bu.enable = true;
  virt-tools.enable = false;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };


  # Adicionar seu usuário ao grupo adbusers (substitua 'seu-usuario' pelo seu nome de usuário real)
  users.users.lluz.extraGroups = [ "adbusers" ];

  services = {
    twingate.enable = lib.mkForce true;
    power-profiles-daemon.enable = false;
    auto-cpufreq.enable = true;
    thermald.enable = true;
    flatpak.enable = true;
    xserver.videoDrivers = [ "amd" ];
    logind.settings.Login = {
      IeAction = "suspend";
      IdleActionSec = "30min";
    };
  };

  boot = {
    kernelPackages = unstable.linuxPackages_latest;
    kernelModules = [ "xt_LOG" "xt_conntrack" "xt_state" "xt_nat" "iptable_filter" "iptable_nat" ];
    loader = {
      efi.canTouchEfiVariables = true;
      timeout = 2;
      systemd-boot.enable = true;
    };
  };


}
