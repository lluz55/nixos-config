---
type: Recommendation
title: "CI para hosts, pacotes e templates"
status: proposta
priority: P1
dependencies: [14-formatacao-treefmt-nix, 06-testes-modulos-criticos]
related: [repository-map]
timestamp: 2026-10-08T00:00:00Z
---

# 1. CI para hosts/pacotes/templates

## Objetivo

Criar uma esteira de CI que valide o flake principal, hosts representativos, pacotes locais e templates antes de qualquer deploy manual.

## Problema e evidência no repositório

O relatório de pesquisa confirma que o flake já possui substituters Cachix em `flake.nix`, mas não havia workflow `.github/workflows` nesta cópia. `flake.nix` expõe `nixosConfigurations` e muitos `packages`, enquanto `templates/bevy/flake.nix` tem `checks` próprios; o flake principal ainda não expõe checks equivalentes.

## Escopo

- Criar workflow que rode `nix flake check --accept-flake-config`.
- Separar checks leves de avaliação de hosts dos builds caros.
- Validar templates com comandos próprios ou `nix flake check` dentro de cada template quando aplicável.
- Usar secrets do provedor de CI para qualquer cache autenticado.

## Não escopo

- Atualizar `flake.lock` no mesmo PR.
- Fazer deploy automático em máquinas reais.
- Colocar tokens Cachix/GitHub em arquivos do repositório.

## Proposta técnica

Adicionar `checks` ao flake principal começando por derivations leves, por exemplo avaliação/build de `system.build.toplevel` para `n100` e `vps-server` em job agendado, e pacotes locais menores em PR. Em CI, aceitar `nixConfig` do flake para usar os substituters já declarados. Templates podem ser verificados por matriz, evitando compilar projetos pesados em toda mudança.

## Etapas

1. Introduzir recomendação 14 para padronizar `nix fmt` e reduzir diffs de CI.
2. Adicionar `checks` mínimos no flake principal.
3. Criar `.github/workflows/ci.yml` com jobs separados: flake, pacotes, templates.
4. Habilitar cache binário com secrets, se disponível.
5. Documentar como reproduzir localmente.

## Dependências

- Recomendação 14 para formatação.
- Recomendação 6 para testes NixOS mais ricos.
- Token GitHub privado já é tratado via SOPS para Nix local; CI deve usar secrets do GitHub, não SOPS do host.

## Riscos

- Builds caros do `agent-of-empires` ou de hosts desktop podem exceder tempo/memória.
- Inputs privados exigem credencial no CI.
- `--accept-flake-config` deve ser deliberado, pois confia nos substituters declarados.

## Critérios de aceitação

- PRs executam `nix flake check --accept-flake-config`.
- Pelo menos um host e dois pacotes locais aparecem em `checks`.
- Templates principais têm validação documentada.
- Falha de avaliação de host bloqueia merge.

## Verificações

- `nix flake check --accept-flake-config`
- `nix flake show`
- Execução do workflow em PR sem secrets vazados nos logs.

## Fontes primárias

- Nix manual: flake output attributes e `checks` — https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake
- Nix manual: `nix flake check` — https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-check
- Cachix Action — https://github.com/cachix/cachix-action
- GitHub Actions encrypted secrets — https://docs.github.com/actions/security-guides/encrypted-secrets
