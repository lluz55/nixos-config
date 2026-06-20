---
name: sops-secrets
description: Gerencia segredos criptografados usando SOPS e age.
---

# Gerenciamento de Segredos com SOPS-NIX

Sempre que precisar criar, visualizar ou editar arquivos criptografados.

## Criando a Chave de Decodificação (Age) a partir de chave SSH
```bash
mkdir -p ~/.config/sops/age
nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt"
```

## Editando Segredos Existentes
Para modificar `secrets/secrets.yaml`:
```bash
sops secrets/secrets.yaml
```

## Adicionando Chaves ao SOPS
Caso uma nova chave pública precise acessar os segredos, atualize o arquivo `.sops.yaml` na raiz do projeto e re-criptografe o arquivo:
```bash
sops updatekeys secrets/secrets.yaml
```
