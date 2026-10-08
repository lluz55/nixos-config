---
type: Concept
title: "Hosts NixOS e topologia"
description: "Resumo dos hosts avaliados, da topologia do n100 e dos cuidados de exposição de rede."
tags: [nixos, hosts, network]
related: [repository-map, homelab-observability]
timestamp: 2026-10-08T00:00:00Z
---

# Hosts NixOS e topologia

## O que é

Este conceito descreve os hosts declarados no flake e a topologia de rede que importa para mudanças de serviços. Use antes de abrir portas, adicionar exporters ou propor deploy remoto.

## Fontes de código

- `flake.nix`: hosts `n100`, `b450`, `s14`, `gl62m`, `thinkpad` e `vps-server`.
- `hosts/n100/default.nix`: servidor/roteador do homelab, automação residencial, gateways locais e serviços de IA.
- `hosts/n100/router/networking.nix`: bridges/VLANs e endereços (`br-lan`, `br-cams`, `vl-mgmt`, `vl-home`, `vl-guests`, `vl-cams`).
- `hosts/n100/router/firewall.nix`: nftables com política de `input` drop e exceções explícitas.
- `hosts/vps-server/disk-config.nix`: uso existente de `disko` no VPS.

## Topologia relevante do n100

1. `n100` é o host mais provável para serviços centrais do homelab: ele já habilita automação residencial, gateways locais e roteamento.
2. A interface WAN não deve receber portas administrativas novas; o firewall usa `policy drop` para `input` e aceita explicitamente tráfego confiável.
3. Redes citadas no firewall: `br-lan`, `br-cams`, `vl-mgmt`, `vl-home`, `vl-guests` e `vl-cams`.
4. Serviços já documentam binds seguros em comentários: vários UIs ficam em loopback e acessíveis por túnel/proxy controlado.
5. O firewall local do NixOS é desativado no n100 porque nftables customizado é a fonte de verdade.

## Regras para mudanças de rede

- Preferir bind em `127.0.0.1` para primeiro incremento administrativo.
- Se uma porta precisar ser acessível pela LAN, restringir a VLANs confiáveis e documentar a regra no nftables.
- Nunca usar `openFirewall = true` como atalho no n100 sem compatibilizar com `hosts/n100/router/firewall.nix`.
- Não expor Prometheus, exporters, dashboards ou APIs administrativas na WAN.

## Referências

- [[repository-map]]
- [[homelab-observability]]
- `hosts/n100/router/firewall.nix`
