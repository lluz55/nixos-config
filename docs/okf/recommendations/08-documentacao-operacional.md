---
type: Recommendation
title: "Documentação operacional"
status: proposta
priority: P1
dependencies: []
related: [repository-map, nixos-hosts]
timestamp: 2026-10-08T00:00:00Z
---

# 8. Documentação operacional

## Objetivo

Transformar conhecimento espalhado em runbooks curtos para rebuild, rollback, segredos, serviços críticos e recuperação.

## Problema e evidência no repositório

Há documentação em `README.md`, `scripts/README.md` e comentários extensos em `hosts/n100/default.nix`. Isso ajuda agentes, mas não substitui runbooks orientados a incidentes. A pesquisa apontou deploy e backups como áreas de risco operacional.

## Escopo

- Índice de operações por host.
- Runbooks para rebuild/rollback, SOPS, containers, automação residencial e observabilidade.
- Inventário de portas expostas e forma de acesso.
- Registro de decisões que não devem ser “limpadas” por agentes.

## Não escopo

- Duplicar todo comentário do código.
- Publicar segredos ou caminhos privados sensíveis além do necessário.
- Documentação genérica de NixOS sem relação com este repo.

## Proposta técnica

Criar `docs/ops/index.md` e páginas por operação crítica. Cada runbook deve ter pré-condições, comando, validação, rollback e riscos. Comentários complexos do `n100` podem ser referenciados por arquivo/linha em vez de copiados integralmente.

## Etapas

1. Listar hosts e serviços críticos.
2. Criar runbook de rebuild e rollback.
3. Criar runbook de segredos SOPS sem valores secretos.
4. Criar runbook de observabilidade para acessar Prometheus via túnel.
5. Adicionar checklist de pós-deploy por host.

## Dependências

Nenhuma obrigatória; esta recomendação destrava backups, deploy, Secure Boot e impermanence.

## Riscos

- Documentação desatualizada pode ser pior que ausência.
- Copiar comandos destrutivos sem pré-condições aumenta risco.
- Expor nomes de recursos privados desnecessários pode vazar topologia.

## Critérios de aceitação

- Existe índice operacional navegável.
- Cada runbook tem rollback/verificação.
- Serviços críticos do `n100` estão listados com método de acesso.
- Secrets são citados só por nome lógico/caminho SOPS.

## Verificações

- Revisão manual cruzando `docs/ops` com `hosts/` e `modules/`.
- `rg -n 'password|token|secret' docs/ops` para conferir ausência de valores.
- Execução local dos comandos não destrutivos.

## Fontes primárias

- NixOS manual: changing configuration — https://nixos.org/manual/nixos/stable/#sec-changing-config
- sops-nix — https://github.com/Mic92/sops-nix
- Diátaxis: how-to guides — https://diataxis.fr/how-to-guides/
