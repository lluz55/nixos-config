---
type: Recommendation
title: "Testes dos módulos críticos"
status: proposta
priority: P1
dependencies: [01-ci-hosts-pacotes-templates]
related: [repository-map]
timestamp: 2026-10-08T00:00:00Z
---

# 6. Testes dos módulos críticos

## Objetivo

Criar testes NixOS pequenos para módulos próprios que definem serviços, portas, secrets ou units systemd.

## Problema e evidência no repositório

O relatório observou módulos próprios como `modules/servers/cloudflared-connector.nix`, `modules/servers/hermes-agent-gateway.nix`, `modules/servers/nostr-sync-relay.nix`, `modules/home-automation` e pacotes em `pkgs/`. Não foi encontrado conjunto principal de `nixosTests` no flake principal.

## Escopo

- Testar que options geram units esperadas.
- Validar que secrets são referenciados por caminho e não em texto.
- Cobrir binds/portas de módulos críticos.
- Integrar testes leves ao `checks` do flake.

## Não escopo

- Simular todo o homelab com câmeras e rede real.
- Testar serviços upstream pesados quando um teste de option basta.
- Substituir health checks operacionais pós-deploy.

## Proposta técnica

Começar com testes de avaliação e VM mínima para um módulo de servidor. Um teste deve importar o módulo, habilitar a opção e confirmar via Python test script que o unit existe, o serviço escuta no endereço esperado ou o arquivo gerado contém a opção segura.

## Etapas

1. Escolher dois módulos críticos de baixa dependência externa.
2. Criar `nixosTests` ou checks que importem os módulos isolados.
3. Adicionar asserts para ports, users e secrets.
4. Conectar ao CI.
5. Expandir após estabilizar tempo de execução.

## Dependências

- CI da recomendação 1.
- Melhor inventário operacional da recomendação 8.

## Riscos

- Testes VM podem ficar lentos se incluírem containers ou serviços de IA.
- Mocks mal feitos testam algo diferente do host real.
- Alguns módulos dependem de inputs privados.

## Critérios de aceitação

- Pelo menos dois módulos próprios têm testes no flake.
- `nix flake check` executa os testes leves.
- Testes falham se porta/bind/security regressionar.
- Tempo total permanece aceitável para PR.

## Verificações

- `nix flake check --accept-flake-config`
- `nix build .#checks.x86_64-linux.<nome-do-teste>`
- Inspeção de logs de teste VM.

## Fontes primárias

- NixOS manual: NixOS tests — https://nixos.org/manual/nixos/stable/#sec-nixos-tests
- NixOS module system — https://nixos.org/manual/nixos/stable/#sec-writing-modules
