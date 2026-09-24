{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.profiles.printing;

  printWrapper = pkgs.writeShellScriptBin "imprimir" ''
    set -euo pipefail
    PRINTER="''${PRINTER_NAME:-Epson_L395}"

    show_help() {
      echo "Uso: imprimir [OPÇÕES] <arquivo1> [arquivo2 ...]"
      echo ""
      echo "Wrapper de impressão para Epson L395 no NixOS."
      echo ""
      echo "Opções:"
      echo "  -h, --help        Exibe esta mensagem de ajuda"
      echo "  -s, --status      Verifica o status da impressora e fila"
      echo "  -c, --cancelar    Cancela todos os trabalhos da fila"
      echo "  -p, --pb, --mono  Imprime em preto e branco (escala de cinza)"
      echo "  -n, --copias N    Define o número de cópias"
      echo "  -o OPCAO          Passa opções extras ao lp (ex: -o media=A4)"
      echo ""
      echo "Exemplos:"
      echo "  imprimir documento.pdf"
      echo "  imprimir -p relatorio.pdf"
      echo "  imprimir -n 2 contrato.pdf"
      echo "  imprimir --status"
    }

    if [ $# -eq 0 ]; then
      show_help
      exit 0
    fi

    LP_ARGS=("-d" "$PRINTER")

    while [ $# -gt 0 ]; do
      case "$1" in
        -h|--help)
          show_help
          exit 0
          ;;
        -s|--status)
          exec ${pkgs.cups}/bin/lpstat -p "$PRINTER" -o
          ;;
        -c|--cancelar)
          ${pkgs.cups}/bin/cancel -a "$PRINTER"
          echo "Fila de impressão de $PRINTER cancelada."
          exit 0
          ;;
        -p|--pb|--mono)
          LP_ARGS+=("-o" "ColorModel=Gray")
          shift
          ;;
        -n|--copias)
          if [ -z "''${2:-}" ]; then
            echo "Erro: informe o número de cópias." >&2
            exit 1
          fi
          LP_ARGS+=("-n" "$2")
          shift 2
          ;;
        -o)
          if [ -z "''${2:-}" ]; then
            echo "Erro: informe o valor da opção." >&2
            exit 1
          fi
          LP_ARGS+=("-o" "$2")
          shift 2
          ;;
        --)
          shift
          LP_ARGS+=("$@")
          break
          ;;
        *)
          LP_ARGS+=("$1")
          shift
          ;;
      esac
    done

    exec ${pkgs.cups}/bin/lp "''${LP_ARGS[@]}"
  '';

  printEpsonSymlink = pkgs.runCommand "print-epson" { } ''
    mkdir -p $out/bin
    ln -s ${printWrapper}/bin/imprimir $out/bin/print-epson
  '';
in
{
  options.profiles.printing = {
    enable = mkEnableOption "impressão via CUPS com drivers Epson ESC/P-R";

    printerIp = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Endereço IP da impressora Epson L395 na rede local para configuração declarativa.";
    };

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

    # Configuração declarativa da impressora CUPS caso o IP esteja definido
    hardware.printers = mkIf (cfg.printerIp != null) {
      ensurePrinters = [
        {
          name = "Epson_L395";
          description = "Epson L395 Multifuncional (Wi-Fi)";
          deviceUri = "socket://${cfg.printerIp}:9100";
          model = "epson-inkjet-printer-escpr/Epson-L395_Series-epson-escpr-en.ppd";
          ppdOptions = {
            PageSize = "A4";
          };
        }
      ];
      ensureDefaultPrinter = "Epson_L395";
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

    # Descoberta direta do scanner em rede via IP
    environment.etc = mkIf (cfg.scanning && cfg.printerIp != null) {
      "sane.d/epson2.conf".text = ''
        net ${cfg.printerIp}
      '';
      "sane.d/epsonds.conf".text = ''
        net ${cfg.printerIp}
      '';
    };

    environment.systemPackages =
      optionals cfg.scanning [ pkgs.simple-scan ]
      ++ [ printWrapper printEpsonSymlink ];
  };
}
