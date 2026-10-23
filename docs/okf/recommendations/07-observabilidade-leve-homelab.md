---
type: Recommendation
title: "Observabilidade leve do homelab"
status: iniciada
priority: P1
dependencies: [08-documentacao-operacional]
related: [homelab-observability, nixos-hosts]
timestamp: 2026-10-08T00:00:00Z
---

# 7. Observabilidade leve do homelab

## Objetivo

Provar coleta de métricas básicas ponta a ponta com Prometheus e node_exporter no `n100`, sem instalar dashboard, logs ou alertas antes de haver necessidade.

## Problema e evidência no repositório

O HEAD já tinha um bloco `services.prometheus.exporters.node` em `hosts/n100/default.nix`, mas sem coletor Prometheus declarando `scrapeConfigs`. O `n100` é o host apropriado porque concentra roteamento, automação residencial e serviços locais; `hosts/n100/router/firewall.nix` tem nftables com política de drop na WAN e comentários de exposição seletiva.

## Escopo

- Módulo NixOS reutilizável em `modules/tools/homelab-observability.nix`.
- Prometheus local em `127.0.0.1:9090`.
- node_exporter local em `127.0.0.1:9002`.
- Scrape target `n100-node` com métricas de CPU, disco, memória, rede, systemd e tempo.

## Não escopo

- Grafana, Loki, Alertmanager ou stack completa.
- Abertura de porta para WAN ou VLANs sem autenticação.
- Exporters remotos antes de definir modelo de acesso.

## Proposta técnica

Ativar `homelabObservability.enable = true` no `n100`. O módulo configura `services.prometheus.enable`, `services.prometheus.scrapeConfigs` e `services.prometheus.exporters.node`. Ambos os serviços fazem bind em loopback e `openFirewall = false`, permitindo acesso humano apenas por túnel ou etapa futura de proxy autenticado.

## Etapas

1. Extrair o exporter existente do host para um módulo reutilizável.
2. Declarar Prometheus central com um target local.
3. Restringir binds a `127.0.0.1`.
4. Avaliar a configuração e conferir exporter/target.
5. Documentar expansão: targets remotos só por VLAN confiável, VPN ou proxy autenticado.

## Dependências

- Recomendação 8 para runbook de acesso e operação.
- Topologia do `n100` descrita em `hosts/n100/router/*`.

## Riscos

- Coletor `systemd` pode aumentar cardinalidade se expandido sem critério.
- Abrir Prometheus para LAN sem autenticação expõe metadados internos.
- Adicionar muitos hosts sem labels padronizados dificulta consultas futuras.

## Critérios de aceitação

- A configuração avaliada mostra `services.prometheus.enable = true`.
- `scrapeConfigs` inclui target `127.0.0.1:9002`.
- node_exporter está habilitado com `openFirewall = false`.
- Nenhuma porta administrativa nova é aceita na WAN.

## Verificações

- `nix eval .#nixosConfigurations.n100.config.services.prometheus.scrapeConfigs --json`
- `nix eval .#nixosConfigurations.n100.config.services.prometheus.exporters.node --json`
- `nix eval .#nixosConfigurations.n100.config.services.prometheus.listenAddress`

## Fontes primárias

- NixOS options: Prometheus — https://search.nixos.org/options?query=services.prometheus
- Prometheus configuration — https://prometheus.io/docs/prometheus/latest/configuration/configuration/
- Prometheus node_exporter — https://github.com/prometheus/node_exporter
