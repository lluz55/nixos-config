---
type: Recommendation
title: "Impermanence seletiva"
status: proposta
priority: P3
dependencies: [02-backups-declarativos-restauracao, 08-documentacao-operacional, 11-disko-demais-hosts]
related: [nixos-hosts]
timestamp: 2026-10-08T00:00:00Z
---

# 13. Impermanence seletiva

## Objetivo

Avaliar root efêmero apenas em hosts onde o ganho operacional compense o risco de perder estado não inventariado.

## Problema e evidência no repositório

A pesquisa não encontrou `impermanence`. O repositório tem estado real: automação residencial, containers, bancos em `data/`, SOPS/age, SSH e serviços do `n100`. Aplicar impermanence sem inventário causaria perda de dados.

## Escopo

- Inventariar persistências obrigatórias por host.
- Começar por host descartável ou servidor novo.
- Declarar persistências com `environment.persistence`.
- Testar reboot/rollback antes de adotar amplamente.

## Não escopo

- Tornar todos os hosts efêmeros.
- Mover volumes sem backup.
- Apagar estado para “limpar” máquina.

## Proposta técnica

Após backups e disko, criar um perfil opcional de impermanence. Persistir explicitamente `/var/lib`, `/etc/ssh`, chaves age/SOPS, estado de NetworkManager/systemd-networkd relevante e volumes de containers. O `n100` só deve entrar após inventário completo.

## Etapas

1. Criar checklist de estado por host.
2. Selecionar piloto de baixo risco.
3. Adicionar input/módulo `impermanence`.
4. Declarar persistências mínimas.
5. Validar reboot, serviços e rollback.

## Dependências

- Backups restauráveis.
- Documentação operacional.
- Layout de disco planejado.

## Riscos

- Persistência incompleta remove chaves SSH, dados de containers ou segredos.
- Diferenças entre hosts tornam módulo genérico perigoso.
- Reboot pode parecer bem-sucedido enquanto serviço perdeu histórico.

## Critérios de aceitação

- Host piloto passa por reboot mantendo identidade e dados necessários.
- Lista de persistências está documentada.
- Backups cobrem dados persistidos.
- Impermanence é opt-in por host.

## Verificações

- `nix eval .#nixosConfigurations.<host>.config.environment.persistence --json`
- `systemctl --failed` após reboot piloto.
- Comparação de dados persistentes antes/depois.

## Fontes primárias

- impermanence — https://github.com/nix-community/impermanence
- NixOS module options — https://search.nixos.org/options
