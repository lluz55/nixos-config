{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.tools.adblock;

  toggle-adblock = pkgs.writeShellScriptBin "toggle-adblock" ''
    #!/usr/bin/env bash
    set -euo pipefail

    HOSTS_ADBLOCK="/var/lib/adblock/hosts.adblock"
    ADBLOCK_DIR="/var/lib/adblock"

    # Garantir que o diretório existe
    mkdir -p "$ADBLOCK_DIR"

    is_active() {
        mountpoint -q /etc/hosts
    }

    send_notification() {
        local title="$1"
        local msg="$2"
        local icon="$3"
        if [ -n "''${SUDO_USER:-}" ]; then
            local user_id
            user_id=$(id -u "$SUDO_USER")
            # Executa como o usuário para exibir a notificação na sessão dele
            sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$user_id/bus" \
                ${pkgs.libnotify}/bin/notify-send -i "$icon" "$title" "$msg" || true
        fi
    }

    flush_dns_cache() {
        # Limpar cache do nscd (padrão do NixOS)
        if systemctl is-active --quiet nscd; then
            nscd -i hosts || systemctl restart nscd || true
        fi

        # Limpar cache do systemd-resolved se estiver ativo
        if systemctl is-active --quiet systemd-resolved; then
            resolvectl flush-caches || true
        fi
    }

    case "''${1:-toggle}" in
        on)
            if is_active; then
                send_notification "Adblock" "Adblock já está ativo" "security-high-symbolic"
                exit 0
            fi
            
            echo "Atualizando lista de bloqueio..."
            if ! ${pkgs.hblock}/bin/hblock -q -c -H /etc/static/hosts -O "$HOSTS_ADBLOCK"; then
                if [ ! -f "$HOSTS_ADBLOCK" ]; then
                    send_notification "Adblock" "Erro ao baixar a lista de bloqueio" "dialog-error"
                    exit 1
                fi
                echo "Falha ao baixar lista nova, usando cache anterior."
            fi
            
            # Fazer o bind mount
            if mount --bind "$HOSTS_ADBLOCK" /etc/hosts; then
                flush_dns_cache
                send_notification "Adblock" "Adblock ativado com sucesso" "security-high-symbolic"
            else
                send_notification "Adblock" "Erro ao ativar o Adblock" "dialog-error"
                exit 1
            fi
            ;;
        off)
            if ! is_active; then
                send_notification "Adblock" "Adblock já está inativo" "security-low-symbolic"
                exit 0
            fi
            
            if umount /etc/hosts; then
                flush_dns_cache
                send_notification "Adblock" "Adblock desativado com sucesso" "security-low-symbolic"
            else
                send_notification "Adblock" "Erro ao desativar o Adblock" "dialog-error"
                exit 1
            fi
            ;;
        toggle)
            if is_active; then
                "$0" off
            else
                "$0" on
            fi
            ;;
        status)
            if is_active; then
                echo "active"
            else
                echo "inactive"
            fi
            ;;
        *)
            echo "Uso: $0 {on|off|toggle|status}"
            exit 1
            ;;
    esac
  '';
in {
  options.tools.adblock = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = mdDoc "Habilita o script toggle-adblock e utilitários de bloqueio de anúncios.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      toggle-adblock
      pkgs.hblock
    ];

    # Permitir rodar o script como root via sudo sem senha para usuários administradores (wheel)
    security.sudo.extraRules = [
      {
        groups = [ "wheel" ];
        commands = [
          {
            command = "${toggle-adblock}/bin/toggle-adblock";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
