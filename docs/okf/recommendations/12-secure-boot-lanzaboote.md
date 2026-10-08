---
type: Recommendation
title: "Secure Boot com Lanzaboote"
status: proposta
priority: P3
dependencies: [02-backups-declarativos-restauracao, 03-deploy-health-rollback, 08-documentacao-operacional]
related: [nixos-hosts]
timestamp: 2026-10-08T00:00:00Z
---

# 12. Secure Boot com Lanzaboote

## Objetivo

Avaliar e habilitar Secure Boot declarativo em máquinas físicas adequadas usando Lanzaboote, começando por ambiente com console local.

## Problema e evidência no repositório

A pesquisa não encontrou `lanzaboote`. `hosts/n100/default.nix` usa `systemd-boot`, e `hosts/vps-server/default.nix` usa GRUB. Secure Boot errado pode impedir boot, então VPS não é primeiro candidato.

## Escopo

- Selecionar uma máquina física com acesso local.
- Introduzir input/módulo Lanzaboote em branch própria.
- Documentar enrolment de chaves com `sbctl`.
- Manter rollback via firmware/gerações.

## Não escopo

- Habilitar em VPS sem console.
- Rotacionar chaves em massa.
- Combinar com migração de disco no mesmo PR.

## Proposta técnica

Começar em laptop/desktop com `systemd-boot`, backup e mídia de recuperação. Adicionar Lanzaboote ao flake, configurar `boot.lanzaboote.enable`, desabilitar `systemd-boot.enable` conforme documentação e registrar comandos `sbctl` fora do store.

## Etapas

1. Escolher host piloto e confirmar suporte UEFI/Secure Boot.
2. Criar backup e plano de recuperação.
3. Adicionar Lanzaboote sem aplicar em máquinas remotas.
4. Executar enrolment manual supervisionado.
5. Registrar verificação pós-boot.

## Dependências

- Backups e rollback operacional.
- Documentação operacional clara.

## Riscos

- Máquina pode ficar sem boot se chaves/loader forem configurados errado.
- Firmware diferente por host muda o procedimento.
- GRUB no VPS exige análise separada.

## Critérios de aceitação

- Host piloto boota com Secure Boot ativo.
- `sbctl status` confirma assinatura esperada.
- Runbook inclui recuperação se Secure Boot falhar.
- Outros hosts permanecem inalterados.

## Verificações

- `bootctl status`
- `sbctl status`
- `nix eval .#nixosConfigurations.<host>.config.boot.lanzaboote.enable`

## Fontes primárias

- Lanzaboote — https://github.com/nix-community/lanzaboote
- NixOS manual: systemd-boot — https://nixos.org/manual/nixos/stable/#sec-boot-loader-systemd-boot
- sbctl — https://github.com/Foxboron/sbctl
