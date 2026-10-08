---
type: Recommendation
title: "Formatação unificada com treefmt-nix"
status: proposta
priority: P0
dependencies: []
related: [repository-map]
timestamp: 2026-10-08T00:00:00Z
---

# 14. Formatação unificada com `treefmt-nix`

## Objetivo

Expor `formatter` e check de formatação no flake principal para Nix, Shell e Markdown.

## Problema e evidência no repositório

O relatório observou que `modules/editors/helix.nix` configura ferramentas como `alejandra` e `shfmt`, mas o flake principal não expõe `formatter` nem integra `treefmt-nix`. O `flake.lock` contém entradas transitivas de `treefmt-nix`, mas isso não significa que o projeto o use diretamente.

## Escopo

- Adicionar input `treefmt-nix` ou usar integração compatível com flake-parts.
- Configurar formatadores para `.nix`, `.sh` e `.md`.
- Expor `formatter.${system}` e check de CI.
- Documentar `nix fmt`.

## Não escopo

- Reformatar todo o repositório no mesmo PR funcional.
- Trocar preferências de editor pessoais.
- Formatar arquivos gerados ou logs históricos.

## Proposta técnica

Integrar `treefmt-nix` no `flake-parts.lib.mkFlake`, configurando `programs.alejandra`, `programs.shfmt` e um formatador Markdown escolhido. Em seguida, rodar formatação em PR separado para manter diff revisável.

## Etapas

1. Adicionar input direto `treefmt-nix`.
2. Configurar módulo flake-parts.
3. Expor `formatter`.
4. Rodar `nix fmt -- --ci` no CI.
5. Fazer PR de reformat separado se o diff for grande.

## Dependências

Nenhuma; esta é recomendação P0 porque melhora as demais.

## Riscos

- Diff massivo dificulta revisão.
- Markdown formatter pode alterar tabelas manualmente alinhadas.
- Conflito entre `nixpkgs-fmt`, `nixfmt` e `alejandra` se não houver decisão explícita.

## Critérios de aceitação

- `nix fmt` funciona no root.
- `nix flake check` inclui check de formatação ou CI roda `treefmt --ci`.
- A escolha de formatadores está documentada.
- Arquivos gerados são excluídos.

## Verificações

- `nix fmt -- --ci`
- `nix eval .#formatter.x86_64-linux.name`
- `nix flake check --accept-flake-config`

## Fontes primárias

- treefmt-nix — https://github.com/numtide/treefmt-nix
- Nix flake formatter output — https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-fmt
