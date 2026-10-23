---
type: Recommendation
title: "Backups declarativos e restauração testada"
status: proposta
priority: P1
dependencies: [08-documentacao-operacional]
related: [repository-map, nixos-hosts]
timestamp: 2026-10-08T00:00:00Z
---

# 2. Backups declarativos e restauração testada

## Objetivo

Proteger estado que não é recriado pelo Nix com backups declarativos, credenciais fora do store e ensaio periódico de restauração.

## Problema e evidência no repositório

A pesquisa não encontrou `restic` no HEAD. Há estado local relevante: `data/aionui-backend.db*`, automação residencial sob `modules/home-automation`, serviços do `n100` com diretórios em `/var/lib`, containers Podman e segredos declarados por SOPS em `hosts/configuration.nix`.

## Escopo

- Usar `services.restic.backups` por host para caminhos persistentes.
- Guardar senha/repositório por SOPS ou arquivo fora do store.
- Criar rotina de teste de restore em diretório temporário.
- Documentar RPO/RTO por classe de dado.

## Não escopo

- Copiar segredos descriptografados para Markdown.
- Fazer backup de artefatos deriváveis do Nix store.
- Migrar layout de disco no mesmo passo.

## Proposta técnica

Começar pelo `n100`, inventariando `/var/lib` de serviços reais e volumes de containers. Declarar um job Restic com `initialize = true`, `paths`, `exclude`, `timerConfig` e arquivos de senha/repositório via SOPS. Acrescentar script ou runbook para `restic restore --target` e validação de integridade.

## Etapas

1. Inventariar diretórios persistentes por serviço.
2. Criar secret SOPS para repositório/senha do Restic.
3. Declarar um backup inicial de baixo risco.
4. Rodar restore em caminho separado e validar arquivos esperados.
5. Registrar periodicidade e responsável operacional.

## Dependências

- Documentação operacional da recomendação 8.
- SOPS já existe no flake e em `hosts/configuration.nix`.

## Riscos

- Backup sem restore testado cria falsa segurança.
- Selecionar caminhos demais aumenta custo e tempo.
- Caminhos de containers podem conter locks ou bancos vivos; exigir hooks ou dumps por serviço.

## Critérios de aceitação

- Pelo menos um host tem `services.restic.backups.<name>` declarativo.
- Segredos não aparecem em texto claro no repositório.
- Existe registro de restore testado com data e comando.
- O backup exclui caches/artefatos recriáveis.

## Verificações

- `nix eval .#nixosConfigurations.n100.config.services.restic.backups --json`
- `systemctl list-timers '*restic*'` no host, após deploy manual futuro.
- `restic check` e restore em diretório temporário.

## Fontes primárias

- NixOS options: `services.restic.backups` — https://search.nixos.org/options?query=services.restic.backups
- Restic documentation — https://restic.readthedocs.io/en/stable/
- sops-nix — https://github.com/Mic92/sops-nix
