---
type: Recommendation
title: "disko nos demais hosts"
status: proposta
priority: P3
dependencies: [02-backups-declarativos-restauracao, 03-deploy-health-rollback, 08-documentacao-operacional]
related: [nixos-hosts]
timestamp: 2026-10-08T00:00:00Z
---

# 11. `disko` nos demais hosts

## Objetivo

Expandir layouts declarativos de disco para hosts reinstaláveis, sem tratar `disko` como ausente no projeto.

## Problema e evidência no repositório

`flake.nix` já inclui `disko` e `vps-server` importa `disko.nixosModules.disko`. `hosts/vps-server/disk-config.nix` declara o layout do VPS. Os demais hosts usam `hardware-configuration.nix`, o que é aceitável para máquinas existentes, mas dificulta reinstalação reproduzível.

## Escopo

- Mapear hosts candidatos a reinstalação.
- Criar `disk-config.nix` por host apenas onde houver backup e console/rollback.
- Integrar com `nixos-anywhere` quando apropriado.
- Documentar risco de destruição de dados.

## Não escopo

- Converter todos os desktops de uma vez.
- Aplicar `disko` em máquina com dados sem backup testado.
- Rodar `nixos-anywhere` neste trabalho.

## Proposta técnica

Usar o VPS como referência estrutural, mas criar layouts específicos por máquina. Para laptops/desktops, começar por host descartável ou novo disco. Cada PR deve incluir diagrama de partições e plano de rollback/restauração.

## Etapas

1. Selecionar primeiro host candidato.
2. Fazer backup e teste de restore.
3. Desenhar layout `disko` equivalente ao uso real.
4. Avaliar o módulo sem executar formatação.
5. Planejar instalação manual supervisionada.

## Dependências

- Backups declarativos testados.
- Deploy/rollback documentados.
- Runbook operacional.

## Riscos

- Erro de layout apaga dados.
- Diferenças UEFI/BIOS e criptografia podem impedir boot.
- `hardware-configuration.nix` ainda pode conter particularidades necessárias.

## Critérios de aceitação

- Host candidato tem `disk-config.nix` avaliado.
- Plano de backup/restore existe antes de aplicar.
- README/runbook explica quando usar `nixos-anywhere`.
- Nenhuma máquina real é reparticionada automaticamente.

## Verificações

- `nix eval .#nixosConfigurations.<host>.config.disko.devices --json`
- Revisão do layout contra `lsblk` real antes da aplicação.
- Restore testado da recomendação 2.

## Fontes primárias

- disko — https://github.com/nix-community/disko
- nixos-anywhere — https://github.com/nix-community/nixos-anywhere
- NixOS installation manual — https://nixos.org/manual/nixos/stable/#sec-installation
