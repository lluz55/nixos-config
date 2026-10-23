---
type: Recommendation
title: "DNS adblock central"
status: proposta
priority: P2
dependencies: [07-observabilidade-leve-homelab, 08-documentacao-operacional]
related: [nixos-hosts]
timestamp: 2026-10-08T00:00:00Z
---

# 10. DNS adblock central

## Objetivo

Adicionar bloqueio DNS central e observável no homelab, integrado à topologia real do `n100`.

## Problema e evidência no repositório

`hosts/n100/router/dnsmasq.nix` já oferece DHCP/DNS local com upstreams `8.8.8.8` e `1.1.1.1`, domínio `lan` e ranges por VLAN. Existe `modules/tools/adblock.nix` importado em `modules/tools/default.nix`, portanto a recomendação deve avaliar o que já existe antes de substituir dnsmasq.

## Escopo

- Definir se o bloqueio fica no dnsmasq atual, em `blocky`/AdGuard Home ou módulo existente.
- Manter DHCP e nomes locais funcionando.
- Expor métricas/logs mínimos para medir bloqueios.
- Restringir administração a loopback/VLAN confiável.

## Não escopo

- Quebrar resolução das VLANs ao trocar tudo de uma vez.
- Abrir UI administrativa para WAN.
- Usar listas de bloqueio sem fonte e licença conhecidas.

## Proposta técnica

Fazer spike comparando manter `dnsmasq` com listas `addn-hosts`/`conf-file` versus introduzir `blocky` como DNS upstream local. Como o `n100` já roteia VLANs, qualquer mudança deve preservar DHCP e regras específicas em `dnsmasq.nix`.

## Etapas

1. Ler `modules/tools/adblock.nix` e confirmar função atual.
2. Definir desenho: dnsmasq puro ou resolver dedicado atrás dele.
3. Testar em uma VLAN confiável primeiro.
4. Adicionar métricas ao Prometheus se o serviço suportar.
5. Documentar rollback para DNS anterior.

## Dependências

- Observabilidade para medir falhas e consultas.
- Documentação operacional para rollback rápido.

## Riscos

- DNS quebrado derruba automação residencial e acesso ao homelab.
- Listas agressivas podem bloquear dispositivos IoT.
- UIs DNS costumam expor dados de navegação; proteger acesso.

## Critérios de aceitação

- Clientes de pelo menos uma rede recebem DNS funcional com bloqueio.
- Nomes locais (`home.lan`, hosts DHCP) continuam resolvendo.
- Existe rollback claro para o dnsmasq atual.
- Métrica ou log mostra consultas bloqueadas sem vazar publicamente.

## Verificações

- `dig @10.0.66.1 home.lan`
- `dig @10.0.66.1 domínio-bloqueado-de-teste`
- `nix eval .#nixosConfigurations.n100.config.services.dnsmasq.settings --json`

## Fontes primárias

- dnsmasq man page — https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
- NixOS options: blocky — https://search.nixos.org/options?query=services.blocky
- AdGuard Home — https://github.com/AdguardTeam/AdGuardHome
