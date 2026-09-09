{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.profiles.printing;
in
{
  options.profiles.printing = {
    enable = mkEnableOption "impressão via CUPS com drivers Epson ESC/P-R";

    scanning = mkOption {
      type = types.bool;
      default = true;
      description = "Habilita SANE + epsonscan2 para o scanner do multifuncional.";
    };
  };

  config = mkIf cfg.enable {
    services.printing = {
      enable = true;
      # PPD Epson-L395_Series-epson-escpr-en.ppd vem deste pacote.
      drivers = [ pkgs.epson-escpr ];
    };

    # mDNS: descoberta automática da impressora na rede local.
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    hardware.sane = mkIf cfg.scanning {
      enable = true;
      # backends epson2/epsonds cobrem USB; epsonscan2 é necessário em rede.
      extraBackends = [ pkgs.epsonscan2 ];
    };

    environment.systemPackages = optionals cfg.scanning [ pkgs.simple-scan ];
  };
}
