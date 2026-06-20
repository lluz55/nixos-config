---
name: nixos-operations
description: Permite construir, testar e implantar as configurações NixOS deste repositório (locais, remotas ou via nixos-anywhere).
---

# Operações de Build e Deploy NixOS

Use esta habilidade quando precisar:
1. Reconstruir a máquina local.
2. Fazer deploy remoto para um servidor/VPS.
3. Implantar uma máquina do zero usando `nixos-anywhere`.

## Comandos Principais

### Build/Rebuild Local
Para testar alterações sem aplicar:
```bash
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
```

Para aplicar as alterações (rebuild switch):
```bash
sudo nixos-rebuild switch --impure --flake .#<host>
```
*Hosts disponíveis no flake*: `n100`, `b450`, `s14`, `gl62m`, `thinkpad`, `vps-server`.

### Deploy em VPS Existente
Para atualizar a configuração da VPS (`vps-server`):
```bash
nixos-rebuild switch --flake .#vps-server --target-host lluz@192.168.0.199
```

### Instalação Limpa com nixos-anywhere
Ao provisionar um novo servidor VPS:
```bash
nix run github:nix-community/nixos-anywhere -- --flake .#vps-server
```
*(Certifique-se de que a chave pública está cadastrada em `./hosts/vps-server/default.nix` sob `users.users.root.openssh.authorizedKeys.keys`)*.
