---
type: Recommendation
title: "Imagens OCI fixadas e hardening"
status: proposta
priority: P1
dependencies: [01-ci-hosts-pacotes-templates, 08-documentacao-operacional]
related: [repository-map, nixos-hosts]
timestamp: 2026-10-08T00:00:00Z
---

# 5. Imagens OCI fixadas e hardening

## Objetivo

Reduzir drift e superfície de ataque de containers declarados pelo NixOS, fixando imagens por digest e endurecendo execução onde possível.

## Problema e evidência no repositório

A pesquisa encontrou tags mutáveis em `hosts/b450/default.nix` (`searxng/searxng:latest`) e em `modules/home-automation/default.nix` (`nodered/node-red`, `docker.io/koenkk/zigbee2mqtt:latest`, `docker.io/eclipse-mosquitto`). Também há imagens versionadas, como Frigate e Home Assistant, então a ação é uniformizar, não introduzir OCI do zero.

## Escopo

- Trocar tags mutáveis por referências `@sha256` para serviços críticos.
- Adicionar health checks Podman quando houver endpoint claro.
- Revisar capabilities, volumes read-only e redes dos containers.
- Documentar procedimento de atualização de digest.

## Não escopo

- Atualizar todos os serviços simultaneamente sem validação.
- Mudar estado/volumes de automação residencial sem backup.
- Esconder segredo em variável de ambiente dentro do store.

## Proposta técnica

Tratar um serviço por PR: registrar digest atual, validar pull, ajustar `virtualisation.oci-containers.containers.<name>.image` e, se suportado, `extraOptions` com `--cap-drop=all`, `--read-only` ou health check. Serviços com escrita legítima devem ter volumes explícitos.

## Etapas

1. Inventariar containers e tags atuais.
2. Definir prioridade: automação residencial e túneis antes de serviços auxiliares.
3. Pin por digest e testar pull.
4. Adicionar hardening compatível com cada imagem.
5. Documentar atualização futura.

## Dependências

- CI ou build local que detecte erro de referência.
- Backups para volumes antes de hardening que mude permissões.

## Riscos

- Digest errado quebra start do container.
- `read-only` pode impedir escrita esperada em `/data` ou `/config`.
- Hardening genérico pode quebrar USB/câmeras/Coral no Frigate.

## Critérios de aceitação

- Nenhum serviço crítico usa `:latest` sem justificativa registrada.
- Cada digest tem rotina de atualização.
- Health check existe onde o serviço oferece endpoint estável.
- Capabilities/volumes são mínimos por serviço, não globais.

## Verificações

- `rg -n ':latest|nodered/node-red|eclipse-mosquitto' hosts modules`
- `nix eval .#nixosConfigurations.n100.config.virtualisation.oci-containers.containers --json`
- `podman image inspect <repo>@sha256:<digest>` em ambiente operacional.

## Fontes primárias

- NixOS options: OCI containers — https://search.nixos.org/options?query=virtualisation.oci-containers.containers
- Podman run reference — https://docs.podman.io/en/latest/markdown/podman-run.1.html
- Podman healthcheck — https://docs.podman.io/en/latest/markdown/podman-healthcheck.1.html
