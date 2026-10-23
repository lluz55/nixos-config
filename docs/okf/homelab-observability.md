---
type: Concept
title: "Observabilidade leve do homelab"
description: "Padrão para métricas básicas com Prometheus e exporters sem introduzir uma pilha completa."
tags: [observability, prometheus, nixos]
related: [repository-map, nixos-hosts]
timestamp: 2026-10-08T00:00:00Z
---

# Observabilidade leve do homelab

## O que é

O primeiro incremento de observabilidade deve provar coleta ponta a ponta com o menor número possível de peças: um exporter no host e um coletor Prometheus central. Dashboards, logs e alertas entram depois de critérios claros.

## Fontes de código

- `modules/tools/homelab-observability.nix`: módulo reutilizável para Prometheus e node_exporter.
- `modules/tools/default.nix`: importação do módulo.
- `hosts/n100/default.nix`: ativação do módulo no coletor central do homelab.
- `hosts/n100/router/firewall.nix`: política de rede que evita exposição pública.

## Ordem de implantação

1. Ativar `services.prometheus.exporters.node` com coletores básicos de CPU, disco, memória, rede e systemd.
2. Ativar `services.prometheus` no mesmo host para raspar o exporter local.
3. Fazer binds em loopback no tracer bullet inicial.
4. Validar por avaliação Nix que o serviço Prometheus, o exporter e o scrape target existem.
5. Só depois documentar expansão para targets remotos por VLAN confiável ou túnel.

## Decisões de segurança

- Prometheus fica em `127.0.0.1:9090` no incremento inicial.
- node_exporter fica em `127.0.0.1:9002` e `openFirewall = false`.
- Não há Grafana, Loki, Alertmanager nem exposição pública neste passo.
- O acesso humano ao Prometheus deve ser por SSH tunnel, Twingate/Netbird ou proxy autenticado em etapa futura.

## Erros comuns de agente

- Instalar uma stack completa antes de provar o scrape local.
- Abrir o exporter para a WAN ou para `0.0.0.0` por conveniência.
- Duplicar configuração diretamente no host em vez de usar módulo reaproveitável.

## Referências

- [[repository-map]]
- [[nixos-hosts]]
- `docs/okf/recommendations/07-observabilidade-leve-homelab.md`
