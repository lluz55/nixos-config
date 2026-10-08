---
type: Recommendation
title: "Atualização automatizada do flake.lock"
status: proposta
priority: P2
dependencies: [01-ci-hosts-pacotes-templates, 14-formatacao-treefmt-nix]
related: [repository-map]
timestamp: 2026-10-08T00:00:00Z
---

# 4. Atualização automatizada do `flake.lock`

## Objetivo

Atualizar inputs do flake de forma recorrente, revisável e com escopo controlado, sem mudanças arbitrárias no lock.

## Problema e evidência no repositório

`flake.lock` é grande e contém inputs sensíveis a versão. `flake.nix` documenta que `agent-of-empires` deve manter o nixpkgs upstream para bater com Cachix, e comentários indicam atualizações isoladas para `pi`/`pi-web`. A regra local em `.agents/AGENTS.md` proíbe atualizar inputs arbitrariamente.

## Escopo

- Automatizar PRs de atualização com agrupamento por input.
- Rodar CI antes de merge.
- Permitir atualização isolada de inputs comentados como especiais.
- Documentar política de rollback do lock.

## Não escopo

- Atualizar `flake.lock` neste trabalho.
- Mudar estratégia do `agent-of-empires` sem medir cache.
- Fazer auto-merge sem checks verdes.

## Proposta técnica

Usar Dependabot para `nix` ou um workflow agendado com `nix flake update --commit-lock-file` em branch de bot. Para inputs especiais, preferir comandos dedicados (`nix flake update pi`) e labels que sinalizem risco. CI da recomendação 1 deve bloquear PRs que quebrem avaliação.

## Etapas

1. Inventariar inputs com política especial.
2. Criar workflow ou configuração Dependabot para PRs semanais.
3. Adicionar labels/descrição com inputs alterados.
4. Exigir CI verde e revisão humana.
5. Registrar comando de rollback para reverter lock.

## Dependências

- CI funcional.
- Política de formatação para evitar diffs irrelevantes.

## Riscos

- Inputs privados podem falhar no CI sem token.
- Atualizações agregadas tornam regressões difíceis de isolar.
- `agent-of-empires` pode voltar a compilar localmente se o follows for alterado.

## Critérios de aceitação

- Bot abre PR de atualização sem commitar secrets.
- PR mostra quais inputs mudaram.
- Checks cobrem pelo menos avaliação dos hosts críticos.
- Inputs especiais têm instrução de atualização separada.

## Verificações

- `nix flake metadata`
- `nix flake check --accept-flake-config`
- Inspeção do diff de `flake.lock` por PR.

## Fontes primárias

- Nix flakes — https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake
- GitHub Dependabot for ecosystems — https://docs.github.com/code-security/dependabot
- GitHub Actions scheduled events — https://docs.github.com/actions/using-workflows/events-that-trigger-workflows#schedule
