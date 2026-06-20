{ config, lib, pkgs, unstable, ... }:
with lib;
{
  options.profiles.desktop.enable = mkEnableOption "common desktop host defaults";

  config = mkIf config.profiles.desktop.enable {
    gnome.enable = mkDefault false;
    hyprland.enable = mkDefault false;
    arduino.enable = mkDefault false;

    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;

    i18n.supportedLocales = mkDefault [
      "en_US.UTF-8/UTF-8"
      "pt_BR.UTF-8/UTF-8"
    ];

    console = {
      font = mkDefault "Lat2-Terminus16";
      keyMap = mkDefault "us";
    };

    hardware.graphics = {
      enable = mkDefault true;
      enable32Bit = mkDefault true;
    };

    hardware.acpilight.enable = mkDefault true;

    environment.systemPackages = with unstable; [
      vscode
      brave
      (vivaldi.override {
        proprietaryCodecs = true;
      })
      vivaldi-ffmpeg-codecs
      qutebrowser
      wl-clipboard
      cosmic-applets
      rustup
      font-awesome_4
      remmina
      x2goclient
      turbovnc
      twingate
    ];
  };
}
