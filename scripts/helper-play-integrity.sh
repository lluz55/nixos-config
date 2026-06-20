#!/usr/bin/env bash
set -euo pipefail

# Find the directory of the script and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Ensure we run as a regular user with sudo access
if [ "$EUID" -eq 0 ]; then
  echo "Please run this script as a normal user (without sudo):"
  echo "  $0"
  exit 1
fi

show_menu() {
    clear
    echo "====================================================================="
    echo "       WAYDROID PLAY INTEGRITY & WHATSAPP BYPASS HELPER"
    echo "   (Baseado no Tutorial do Reddit: Keystore Válido & TrickyStore)"
    echo "====================================================================="
    echo " 1) [PREPARAÇÃO] Desativar Zygisk nativo no app do Magisk (Instruções)"
    echo " 2) [PASSO 1]    Instalar standalone Zygisk Next (ReZygisk)"
    echo " 3) [PASSO 2]    Instalar Play Integrity Fix (Fork do osm0sis)"
    echo " 4) [PASSO 3]    Instalar Tricky Store (Falsificador de Keystore v1.4.1)"
    echo " 5) [PASSO 4]    Configurar diretório do Tricky Store & target.txt"
    echo " 6) [STATUS]     Verificar status dos serviços e do contêiner"
    echo " 7) [REINICIAR]  Reiniciar contêiner do Waydroid (Aplicar alterações)"
    echo " 0) Sair"
    echo "====================================================================="
    echo -n "Escolha uma opção [0-7]: "
}

while true; do
    show_menu
    read -r opt
    case $opt in
        1)
            echo ""
            echo "=== INSTRUÇÕES DE PREPARAÇÃO ==="
            echo "1. Abra o aplicativo do Magisk dentro do Waydroid."
            echo "2. Clique no ícone de Engrenagem (Configurações) no canto superior direito."
            echo "3. Procure pela opção 'Zygisk' e certifique-se de que ela está DESATIVADA."
            echo "   (O Zygisk nativo do Magisk causa conflitos com o Zygisk Next/ReZygisk)."
            echo "4. Se você precisou desativar, reinicie o contêiner usando a opção 7."
            echo ""
            read -n 1 -s -r -p "Pressione qualquer tecla para voltar ao menu..."
            ;;
        2)
            echo ""
            echo "=== PASSANDO PARA PASSO 1: INSTALAR ZYGISK NEXT ==="
            if [ -f "$SCRIPT_DIR/install-zygisk-next.sh" ]; then
                "$SCRIPT_DIR/install-zygisk-next.sh"
            else
                echo "Erro: Script install-zygisk-next.sh não encontrado."
            fi
            echo ""
            read -n 1 -s -r -p "Pressione qualquer tecla para voltar ao menu..."
            ;;
        3)
            echo ""
            echo "=== PASSANDO PARA PASSO 2: INSTALAR PLAY INTEGRITY FIX ==="
            if [ -f "$SCRIPT_DIR/install-play-integrity-fix.sh" ]; then
                "$SCRIPT_DIR/install-play-integrity-fix.sh"
            else
                echo "Erro: Script install-play-integrity-fix.sh não encontrado."
            fi
            echo ""
            read -n 1 -s -r -p "Pressione qualquer tecla para voltar ao menu..."
            ;;
        4)
            echo ""
            echo "=== PASSANDO PARA PASSO 3: INSTALAR TRICKY STORE ==="
            if [ -f "$SCRIPT_DIR/install-tricky-store.sh" ]; then
                "$SCRIPT_DIR/install-tricky-store.sh"
            else
                echo "Erro: Script install-tricky-store.sh não encontrado."
            fi
            echo ""
            read -n 1 -s -r -p "Pressione qualquer tecla para voltar ao menu..."
            ;;
        5)
            echo ""
            echo "=== PASSANDO PARA PASSO 4: CONFIGURAR TRICKY STORE ==="
            if [ -f "$SCRIPT_DIR/configure-tricky-store.sh" ]; then
                "$SCRIPT_DIR/configure-tricky-store.sh"
            else
                echo "Erro: Script configure-tricky-store.sh não encontrado."
            fi
            echo ""
            read -n 1 -s -r -p "Pressione qualquer tecla para voltar ao menu..."
            ;;
        6)
            echo ""
            echo "=== STATUS ATUAL DO WAYDROID ==="
            waydroid status
            echo ""
            read -n 1 -s -r -p "Pressione qualquer tecla para voltar ao menu..."
            ;;
        7)
            echo ""
            echo "=== REINICIANDO CONTÊINER WAYDROID ==="
            echo "Reiniciando o serviço waydroid-container.service..."
            sudo systemctl restart waydroid-container.service
            echo "Serviço reiniciado com sucesso!"
            echo ""
            read -n 1 -s -r -p "Pressione qualquer tecla para voltar ao menu..."
            ;;
        0)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo "Opção inválida. Tente novamente."
            sleep 1
            ;;
    esac
done
