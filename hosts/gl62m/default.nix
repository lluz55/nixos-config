{ pkgs, lib, config, ... }:
with lib; {
  imports = [
    ../../modules
    ./hardware-configuration.nix
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;

    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:0:1:0";
    };
  };

  gnome.enable = true;

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
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      grub = {
        enable = true;
        devices = [ "/dev/sda" ];
        useOSProber = true;
        configurationLimit = 2;
        theme = pkgs.stdenv.mkDerivation {
          pname = "distro-grub-themes";
          version = "3.1";
          src = pkgs.fetchFromGitHub {
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
  #    package = pkgs.nix-direnv;
  #  };
  #};

  #sway.enable = true;

  environment = {
    systemPackages = with pkgs; [
      vscode
      nmap
      remmina
      x2goclient
      turbovnc
      lazygit
      vivaldi
    ];
  };
}
