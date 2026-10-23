---
type: Index
title: "Índice OKF"
description: "Mapa de conceitos e tarefas para este flake NixOS."
tags: [okf, index, nixos]
timestamp: 2026-10-08T00:00:00Z
---

# Índice OKF

## Conceitos

| Conceito | Quando ler | Arquivo |
|---|---|---|
| Mapa do repositório NixOS | Antes de alterar módulos, flake, pacotes, templates ou documentação estrutural. | [repository-map](./repository-map.md) |
| Hosts NixOS e topologia | Antes de mudar serviços por host, portas, firewall ou deploy. | [nixos-hosts](./nixos-hosts.md) |
| Observabilidade leve do homelab | Antes de mexer em Prometheus, exporters, métricas ou documentação da recomendação 7. | [homelab-observability](./homelab-observability.md) |

## Mapas de trabalho

| Trabalho | Conceitos recomendados | Tarefa |
|---|---|---|
| Documentar recomendações de melhoria | `repository-map`, `nixos-hosts` | [001-documentar-recomendacoes-e-observabilidade](../tasks/001-documentar-recomendacoes-e-observabilidade.md) |
| Implementar observabilidade leve | `homelab-observability`, `nixos-hosts`, `repository-map` | [001-documentar-recomendacoes-e-observabilidade](../tasks/001-documentar-recomendacoes-e-observabilidade.md) |

## Recomendações

As recomendações detalhadas ficam em [recommendations/index.md](./recommendations/index.md). O índice de recomendações referencia exatamente 15 documentos, um por recomendação.

## Protocolo local para agentes

1. Leia este índice primeiro.
2. Escolha no máximo três conceitos relevantes.
3. Confira `docs/tasks/index.md` e a tarefa individual.
4. Leia `.agents/AGENTS.md` antes de editar.
5. Atualize a tarefa após implementar.
