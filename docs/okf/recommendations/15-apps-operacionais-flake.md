---
type: Recommendation
title: "Apps operacionais do flake"
status: proposta
priority: P2
dependencies: [03-deploy-health-rollback, 08-documentacao-operacional]
related: [repository-map]
timestamp: 2026-10-08T00:00:00Z
---

# 15. Apps operacionais do flake

## Objetivo

Expor comandos operacionais seguros via `nix run .#...`, evitando scripts soltos e caminhos manuais divergentes.

## Problema e evidência no repositório

`flake.nix` expõe muitos `packages`, mas não há seção `apps` operacional no flake principal. Há scripts em `scripts/` para deploy, instalação ARM/Waydroid e sincronização de modelos. Sem apps, operadores precisam lembrar caminhos e pré-condições.

## Escopo

- Criar apps para ações read-only ou de baixo risco primeiro.
- Envolver scripts existentes com help e validações.
- Expor comandos como `deploy-n100-dry-run`, `waydroid-doctor` e `sync-models` quando maduros.
- Documentar quais apps podem alterar estado.

## Não escopo

- Transformar scripts destrutivos em comandos de um clique sem confirmação.
- Executar deploy real neste trabalho.
- Mover secrets para argumentos de linha de comando.

## Proposta técnica

Adicionar `apps.${system}` no `perSystem` do flake, apontando para wrappers `writeShellApplication` ou pacotes em `pkgs/`. Cada app deve validar diretório, exibir plano e exigir flag explícita para ações mutáveis. Apps read-only podem entrar no CI.

## Etapas

1. Classificar scripts por risco.
2. Criar primeiro app read-only (`waydroid-doctor --check` ou inventário de hosts).
3. Adicionar `--help` consistente.
4. Documentar no índice operacional.
5. Integrar checks de shell/formatação.

## Dependências

- Runbooks da recomendação 8.
- Fluxo de deploy da recomendação 3 para apps de rebuild.
- Recomendação 9 para Waydroid.

## Riscos

- Apps com nomes ambíguos podem induzir execução destrutiva.
- Wrappers podem divergir dos scripts se não houver testes.
- `nix run` com argumentos secretos pode registrar histórico de shell.

## Critérios de aceitação

- `nix flake show` lista apps operacionais.
- Apps read-only rodam sem sudo.
- Apps mutáveis exigem confirmação/flag clara.
- Documentação diferencia dry-run de execução real.

## Verificações

- `nix flake show --all-systems`
- `nix run .#<app> -- --help`
- Testes de shell após recomendação 6/14.

## Fontes primárias

- Nix flake apps and `nix run` — https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-run
- Nixpkgs `writeShellApplication` — https://nixos.org/manual/nixpkgs/stable/#trivial-builder-writeShellApplication
