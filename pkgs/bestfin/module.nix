{ config, lib, pkgs, ... }:
let
  cfg = config.programs.bestfin;

  desktopItem = pkgs.makeDesktopItem {
    name = "bestfin";
    desktopName = "BestFin";
    comment = "Personal finance app";
    exec = "bestfin";
    icon = "bestfin";
    terminal = false;
    categories = [ "Office" "Finance" ];
    startupWMClass = "bestfin";
  };

  # O tarball de release nao traz .desktop nem icone instalado; montamos aqui
  # a partir do asset embarcado no bundle Flutter.
  icon = pkgs.runCommand "bestfin-icon" { } ''
    mkdir -p $out/share/icons/hicolor/512x512/apps
    cp ${cfg.package}/lib/bestfin/data/flutter_assets/assets/images/app_icon.png \
      $out/share/icons/hicolor/512x512/apps/bestfin.png
  '';
in
{
  options.programs.bestfin = {
    enable = lib.mkEnableOption "BestFin personal finance desktop app";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = "BestFin package to install (prebuilt release bundle).";
    };

    desktopEntry = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Instalar entrada .desktop e icone para o BestFin.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      [ cfg.package ] ++ lib.optionals cfg.desktopEntry [ desktopItem icon ];
  };
}
