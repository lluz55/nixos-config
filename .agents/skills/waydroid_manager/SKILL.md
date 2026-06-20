---
name: waydroid-manager
description: Gerencia o ambiente Waydroid no host NixOS, incluindo a execução dos scripts de Magisk, Zygisk Next, Play Integrity e tradução ARM.
---

# Gerenciamento do Waydroid com Magisk e Tradutores

Use esta habilidade quando for solicitado a instalar, configurar ou atualizar o ambiente Android (Waydroid) e seus complementos.

## Sequência Correta de Instalação

Os scripts devem ser executados a partir da raiz do projeto na seguinte ordem:

1. **Magisk (como usuário normal)**:
   ```bash
   ./scripts/install-magisk.sh
   ```
2. **Zygisk Next (como usuário normal)**:
   ```bash
   ./scripts/install-zygisk-next.sh
   ```
3. **Play Integrity Fix (como usuário normal)**:
   ```bash
   ./scripts/install-play-integrity-fix.sh
   ```
4. **Camada de Tradução ARM (como root/sudo)**:
   ```bash
   sudo ./scripts/install-arm.sh
   ```
   *Nota: Por padrão, o script detecta o processador e usa `libndk` para CPUs AMD ou `libhoudini` para Intel/outros. É possível forçar passando o argumento explicitamente.*

## Reinicialização do Container
Sempre após instalar novos módulos Magisk, reinicie o container do Waydroid:
```bash
sudo systemctl restart waydroid-container.service
```

## Resolução de Problemas
- Verificar status: `waydroid status` ou `sudo systemctl status waydroid-container.service`.
- Log do container: `sudo journalctl -u waydroid-container.service`.
