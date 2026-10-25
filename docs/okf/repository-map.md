---
type: Concept
title: "Mapa do repositório NixOS"
description: "Estrutura mínima para navegar hosts, módulos, pacotes, templates e documentação operacional deste flake."
tags: [nixos, flake, repository]
related: [nixos-hosts, homelab-observability]
timestamp: 2026-10-08T00:00:00Z
---

# Mapa do repositório NixOS

## O que é

Este conceito resume onde ficam os blocos reutilizáveis e onde uma mudança deve ser conectada. Use quando a tarefa envolver documentação de recomendações, módulos NixOS ou avaliação do flake principal.

## Fontes de código

- `flake.nix`: declara inputs, `nixosConfigurations`, pacotes locais e templates.
- `hosts/`: configurações por máquina (`n100`, `b450`, `s14`, `gl62m`, `thinkpad`, `vps-server`).
- `hosts/configuration.nix`: base compartilhada por hosts do perfil desktop, incluindo SOPS, Podman, SSH e configurações Nix.
- `modules/`: módulos reutilizáveis por tema (`tools`, `servers`, `home-automation`, `waydroid`, etc.).
- `pkgs/`: empacotamentos e módulos Nix próprios.
- `templates/`: templates de projetos expostos pelo flake.
- `scripts/`: scripts operacionais manuais, incluindo deploy/instalação.
- `docs/research/nixos-config-improvements.md`: relatório-base de melhorias usado pelas recomendações.

## Padrões locais observados

1. O flake já usa `flake-parts`; recomendações devem melhorar a organização atual, não propor migração genérica para flake-parts.
2. Módulos reutilizáveis pertencem a `modules/` e devem ser importados por um agregador como `modules/tools/default.nix` ou `modules/servers/default.nix`.
3. Hosts só devem conter a ativação e exceções específicas da máquina quando houver módulo reutilizável possível.
4. Segredos ficam em SOPS; não escrever tokens, senhas ou chaves em Nix/Markdown.
5. Não atualizar `flake.lock` sem necessidade explícita.

## Pacote 9Router

`pkgs/9router/package.nix` fixa versão e `npmDepsHash`; `package.json` e `package-lock.json` fixam dependências npm. Versão 0.5.109 construída com sucesso; ativação no host ainda pendente de sudo. Evidências e estado: [tarefa 004](../tasks/004-update-9router.md). Não atualizar inputs do flake para esse bump.

## Erros comuns de agente

- Declarar serviço genérico diretamente em `hosts/n100/default.nix` quando ele poderia ser um módulo reutilizável.
- Recomendar `disko`, `sops-nix` ou `flake-parts` como ausentes sem checar o HEAD; eles já aparecem no repositório.
- Criar documentação operacional sem apontar arquivos concretos do repositório.

## Referências

- [[nixos-hosts]]
- [[homelab-observability]]
- `docs/research/nixos-config-improvements.md`
