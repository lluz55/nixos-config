---
type: Index
title: "Recomendações de melhoria do flake NixOS"
description: "Navegação OKF para as 15 recomendações derivadas da pesquisa do repositório."
tags: [okf, recommendations, nixos]
timestamp: 2026-10-08T00:00:00Z
---

# Recomendações de melhoria do flake NixOS

Base: [`docs/research/nixos-config-improvements.md`](../../research/nixos-config-improvements.md). Estados: `proposta` ainda não implementada, `iniciada` tem primeiro incremento neste branch.

| # | Recomendação | Estado | Prioridade | Dependências | Documento |
|---:|---|---|---|---|---|
| 1 | CI para hosts/pacotes/templates | proposta | P1 | 14, 6 | [01-ci-hosts-pacotes-templates.md](./01-ci-hosts-pacotes-templates.md) |
| 2 | Backups declarativos e restauração testada | proposta | P1 | 8, SOPS existente | [02-backups-declarativos-restauracao.md](./02-backups-declarativos-restauracao.md) |
| 3 | Deploy/health check/rollback unificados | proposta | P2 | 1, 6, 8 | [03-deploy-health-rollback.md](./03-deploy-health-rollback.md) |
| 4 | Atualização automatizada do `flake.lock` | proposta | P2 | 1, 14 | [04-atualizacao-automatizada-flake-lock.md](./04-atualizacao-automatizada-flake-lock.md) |
| 5 | Imagens OCI fixadas e hardening | proposta | P1 | 1, 8 | [05-imagens-oci-fixadas-hardening.md](./05-imagens-oci-fixadas-hardening.md) |
| 6 | Testes dos módulos críticos | proposta | P1 | 1 | [06-testes-modulos-criticos.md](./06-testes-modulos-criticos.md) |
| 7 | Observabilidade leve do homelab | iniciada | P1 | 8 | [07-observabilidade-leve-homelab.md](./07-observabilidade-leve-homelab.md) |
| 8 | Documentação operacional | proposta | P1 | nenhuma | [08-documentacao-operacional.md](./08-documentacao-operacional.md) |
| 9 | `waydroid-doctor` e perfis | proposta | P2 | 6, 8 | [09-waydroid-doctor-perfis.md](./09-waydroid-doctor-perfis.md) |
| 10 | DNS adblock central | proposta | P2 | 7, 8 | [10-dns-adblock-central.md](./10-dns-adblock-central.md) |
| 11 | `disko` nos demais hosts | proposta | P3 | 2, 3, 8 | [11-disko-demais-hosts.md](./11-disko-demais-hosts.md) |
| 12 | Secure Boot com Lanzaboote | proposta | P3 | 2, 3, 8 | [12-secure-boot-lanzaboote.md](./12-secure-boot-lanzaboote.md) |
| 13 | Impermanence seletiva | proposta | P3 | 2, 8, 11 | [13-impermanence-seletiva.md](./13-impermanence-seletiva.md) |
| 14 | Formatação unificada com `treefmt-nix` | proposta | P0 | nenhuma | [14-formatacao-treefmt-nix.md](./14-formatacao-treefmt-nix.md) |
| 15 | Apps operacionais do flake | proposta | P2 | 3, 8 | [15-apps-operacionais-flake.md](./15-apps-operacionais-flake.md) |

## Ordem sugerida

Começar por 14 e 1 reduz ruído e cria verificação comum. Em paralelo, 8 registra runbooks mínimos. A recomendação 7 já tem o primeiro tracer bullet implementado no `n100`, e as próximas expansões devem manter a restrição de bind/firewall documentada.
