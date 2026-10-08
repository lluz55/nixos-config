---
type: Recommendation
title: "waydroid-doctor e perfis"
status: proposta
priority: P2
dependencies: [06-testes-modulos-criticos, 08-documentacao-operacional]
related: [repository-map]
timestamp: 2026-10-08T00:00:00Z
---

# 9. `waydroid-doctor` e perfis

## Objetivo

Criar uma ferramenta operacional que diagnostique Waydroid, scripts auxiliares e perfis de uso sem exigir tentativa manual repetitiva.

## Problema e evidência no repositório

Há módulo `modules/waydroid`, pacote `pkgs/waydroidsu` e vários scripts (`install-magisk.sh`, `install-arm.sh`, `install-play-integrity-fix.sh`, `install-tricky-store.sh`, `install-zygisk-next.sh`, `helper-play-integrity.sh`). `scripts/README.md` já documenta parte do fluxo, mas não há comando único que diga se o ambiente está saudável.

## Escopo

- Criar app ou pacote `waydroid-doctor` no flake.
- Verificar serviço `waydroid-container.service`, status do Waydroid, presença de scripts e pré-condições.
- Separar perfis: básico, ARM translation, Play Integrity/Magisk.
- Reportar próximos passos sem executar mudanças destrutivas por padrão.

## Não escopo

- Baixar APKs/ZIPs automaticamente sem confirmação.
- Embutir credenciais ou arquivos proprietários.
- Corrigir Play Integrity como garantia permanente.

## Proposta técnica

Implementar script em `pkgs/` ou `scripts/` exposto via `apps` do flake. O modo padrão roda checks read-only; flags explícitas podem chamar scripts existentes. Perfis NixOS podem agrupar pacotes/serviços, mas a mutação dentro do container continua operacional e documentada.

## Etapas

1. Inventariar scripts e pré-condições.
2. Criar checks read-only: status, storage, seccomp, presença de `waydroidsu`.
3. Expor app `waydroid-doctor`.
4. Documentar perfis e riscos.
5. Adicionar teste de shell básico.

## Dependências

- Recomendação 15 para apps operacionais do flake.
- Recomendação 8 para runbook.
- Recomendação 6 para teste de script.

## Riscos

- Scripts existentes usam `sudo` e alteram estado do container.
- Diagnóstico pode ficar obsoleto com mudanças upstream do Waydroid.
- Perfil agressivo pode quebrar um ambiente já funcional.

## Critérios de aceitação

- `nix run .#waydroid-doctor` executa checks sem modificar estado.
- Saída indica comandos manuais para correção.
- Perfis são documentados e separados por risco.
- Falhas comuns têm mensagens acionáveis.

## Verificações

- `nix run .#waydroid-doctor -- --help`
- `shellcheck scripts/*.sh` quando formatação/testes forem introduzidos.
- Teste em host com Waydroid antes de qualquer modo mutável.

## Fontes primárias

- Waydroid documentation — https://docs.waydro.id/
- Nix flake apps — https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-run
- ShellCheck — https://www.shellcheck.net/
