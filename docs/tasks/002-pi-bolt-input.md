---
type: Task
title: "Atualizar Pi-Bolt via input independente"
description: "Compartilhar instalação declarativa entre s14 e n100 e atualizar com nix flake update pi-bolt."
status: completed
priority: P2
dependencies: []
concepts: [repository-map, nixos-hosts]
timestamp: 2026-10-22T00:00:00Z
---

# Pi-Bolt via input independente

- [x] Adicionar input não-flake da release estável mais recente, fixado por hash no flake.lock.
- [x] Consumir mesmo input no pacote local e instalação compartilhada de s14 e n100.
- [x] Construir pacote e confirmar execução: `1.3.0 (Pi-Bolt 0.9.9, linux-x64, JIT off)`.
- [x] Avaliar s14 e n100; n100 exige `--impure` por referência local preexistente a `/home/lluz/dev/dl_home_control`.

Atualização: `nix flake update pi-bolt`. Depois executar rebuild em cada host.
Nenhum rebuild aplicado nesta tarefa.
