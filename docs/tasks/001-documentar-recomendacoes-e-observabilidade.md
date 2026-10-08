---
type: Task
title: "Documentar recomendações e iniciar observabilidade leve"
description: "Registrar as 15 recomendações OKF e entregar o primeiro tracer bullet de observabilidade no n100."
status: in-progress
priority: P1
dependencies: []
concepts: [repository-map, nixos-hosts, homelab-observability]
timestamp: 2026-10-08T00:00:00Z
---

# Documentar recomendações e iniciar observabilidade leve

## Objetivo

Escrever no disco o conjunto completo de 15 recomendações da análise do projeto, no padrão OKF, e iniciar a recomendação 7 com uma configuração NixOS pequena e avaliável para métricas básicas do homelab.

## Checklist

- [x] Ler/criar `docs/okf/index.md` e selecionar até três conceitos relevantes.
- [x] Conferir `docs/tasks/index.md`; como não existia, criar esta tarefa e o índice.
- [x] Ler `.agents/AGENTS.md` antes de alterar configuração.
- [x] Recuperar e versionar `docs/research/nixos-config-improvements.md` da branch preservada.
- [x] Criar `docs/okf/recommendations/index.md` com exatamente 15 links para arquivos existentes.
- [x] Criar um arquivo detalhado por recomendação com frontmatter OKF e seções exigidas.
- [x] Implementar módulo NixOS reutilizável de observabilidade leve com Prometheus e node_exporter.
- [x] Ativar o primeiro tracer bullet no `n100` sem expor portas administrativas publicamente.
- [x] Avaliar a configuração e confirmar Prometheus/exporter/target no resultado avaliado.

## Progresso

9/9 concluídos. Próximas etapas ficam registradas nos documentos das recomendações, especialmente a expansão segura da recomendação 7 para outros hosts.

## Verificações registradas

- `nix eval .#nixosConfigurations.n100.config.services.prometheus.scrapeConfigs --json`
- `nix eval .#nixosConfigurations.n100.config.services.prometheus.exporters.node --json`
- `nix flake check`
