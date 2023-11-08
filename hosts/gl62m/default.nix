{ pkgs, lib, var, config, ... }:
with lib; {
  imports = [
    ../../modules
    ./hardware-configuration.nix
  ];

  # Enable nvidia drivers
  nvidia.enable = true;

  gnome.enable = true;

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

  #sway.enable = true;

  environment = {
    systemPackages = with pkgs; [ ];
  };
}
