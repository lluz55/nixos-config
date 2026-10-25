---
type: Task
title: "Atualizar 9Router para 0.5.109"
task_status: blocked
depends_on: []
---

# Atualizar 9Router

- [x] Conferir versão publicada no registro npm: 0.5.109.
- [x] Atualizar versão, lockfile e npmDepsHash em `pkgs/9router/`.
- [x] Validar `nix build .#9router --no-link`, `git diff --check` e versão via `nix eval`: aprovados.
- [ ] Ativar serviço atualizado; versão em execução permanece 0.5.104.

Build aprovado. `sudo -n true` recusado: `interactive authentication is required`.
Ativação depende de autenticação do operador. Há alterações preexistentes em configuração e flake; revisar antes de reconstruir sistema inteiro.
