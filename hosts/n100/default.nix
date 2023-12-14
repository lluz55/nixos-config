{ pkgs, config, lib, unstable, ... }:

let
  gasketRev = "09385d485812088e04a98a6e1227bf92663e0b59";
  gasketPkg = (pkgs.gasket.overrideAttrs (final: prev: {
    version = builtins.substring 0 6 gasketRev;
    src = pkgs.fetchFromGitHub {
      owner = "google";
      repo = "gasket-driver";
      rev = gasketRev;
      hash = "sha256-fcnqCBh04e+w8g079JyuyY2RPu34M+/X+Q8ObE+42i4=";
    };
  })).override {
    kernel = config.boot.kernelPackages.kernel;
  };
in
with lib;{
  imports = [
    ./../../modules
    ./hardware-configuration.nix
    ./virt.nix
    ./router.nix
    ./frigate.nix
  ];

  gnome.enable = true;

  services.tailscale.enable = true;

  services.openssh = {
    enable = true;
    passwordAuthentication = true;
  };
  environment.systemPackages = with unstable; [
    tailscale
    lm_sensors
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 2;
    };
    extraModulePackages = [ gasketPkg ];
  };

  programs.light.enable = true;
}
