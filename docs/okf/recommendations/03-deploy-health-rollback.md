---
type: Recommendation
title: "Deploy, health check e rollback unificados"
status: proposta
priority: P2
dependencies: [01-ci-hosts-pacotes-templates, 06-testes-modulos-criticos, 08-documentacao-operacional]
related: [nixos-hosts]
timestamp: 2026-10-08T00:00:00Z
---

# 3. Deploy/health check/rollback unificados

## Objetivo

Padronizar como cada host é reconstruído, verificado e revertido, reduzindo scripts manuais divergentes.

## Problema e evidência no repositório

Há scripts manuais como `scripts/deploy-n100.sh` e `scripts/install-arm.sh`. O relatório não encontrou `deploy-rs` e observou instruções de `nixos-rebuild` no README. O `n100` acumula serviços críticos, então deploy sem health checks aumenta risco operacional.

## Escopo

- Escolher fluxo oficial: `nixos-rebuild --target-host` simples ou `deploy-rs`.
- Definir health checks por host após switch.
- Documentar rollback de geração.
- Manter deploy real fora da automação deste branch.

## Não escopo

- Executar deploy em máquina real.
- Trocar chaves SSH ou criar secrets.
- Reinstalar hosts com `nixos-anywhere`.

## Proposta técnica

Começar com um wrapper declarativo/flake app que avalia a configuração, faz dry-run/build e lista health checks a serem executados manualmente. Se a operação multi-host crescer, introduzir `deploy-rs` com nós `n100` e `vps-server`, mantendo rollback explícito por geração NixOS.

## Etapas

1. Levantar comandos atuais em `scripts/` e README.
2. Definir checks mínimos por host: SSH, serviços críticos e portas esperadas.
3. Criar comando único para build + switch remoto, sem secrets embutidos.
4. Registrar rollback: `nixos-rebuild switch --rollback` e seleção de geração no boot.
5. Integrar com CI após recomendação 1.

## Dependências

- CI e testes para reduzir deploys quebrados.
- Documentação operacional para o operador humano.
- Observabilidade ajuda a medir pós-deploy, mas não deve ser pré-requisito rígido.

## Riscos

- Automatizar rollback sem saber o estado do serviço pode mascarar falhas.
- Deploy remoto mal parametrizado pode derrubar o próprio canal SSH.
- `deploy-rs` adiciona complexidade se houver só um host frequente.

## Critérios de aceitação

- Existe um fluxo documentado e reproduzível por host.
- Health checks têm comandos concretos e critérios de sucesso.
- Rollback é descrito antes de qualquer automação destrutiva.
- O fluxo não exige copiar secrets para o repositório.

## Verificações

- `nix build .#nixosConfigurations.n100.config.system.build.toplevel`
- `nixos-rebuild dry-run --flake .#n100 --target-host <host>` em operação manual futura.
- Health checks definidos em runbook.

## Fontes primárias

- NixOS manual: changing configuration — https://nixos.org/manual/nixos/stable/#sec-changing-config
- deploy-rs — https://github.com/serokell/deploy-rs
- NixOS generations/rollback — https://nixos.org/manual/nixos/stable/
