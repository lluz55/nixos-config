---
type: Task
title: "Atualizar CodeAF via input independente"
description: "Usar release upstream fixada no flake.lock no pacote CodeAF instalado pelo Home Manager no s14."
status: completed
priority: P2
dependencies: []
concepts: [repository-map]
timestamp: 2026-10-22T00:00:00Z
---

# CodeAF via input independente

- [x] Identificar pacote declarativo 0.7.1 e binário local em `~/.codeaf/bin/codeaf` com precedência no PATH do s14.
- [x] Adicionar input não-flake do binário upstream mais recente, fixado no lock, compartilhado entre pacote exposto e hosts.
- [x] Construir pacote, executar `--version` e confirmar pacote na avaliação Home Manager do s14.

Atualização: `nix flake update codeaf`. Aplicação: `sudo nixos-rebuild switch --flake .#s14`.
O binário em `~/.codeaf/bin/codeaf` continua tendo precedência no PATH atual: remover essa entrada do PATH ou chamar `/etc/profiles/per-user/lluz/bin/codeaf` explicitamente para usar instalação declarativa.
Nenhum rebuild aplicado; instalação local preservada.
