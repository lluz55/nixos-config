# Pesquisa: melhorias e novas funcionalidades para este flake NixOS

Data: 2026-10-08. Escopo inspecionado: `flake.nix`, `hosts/`, `modules/`, `pkgs/`, `templates/`, `scripts/`, `README.md` e documentação existente. Este relatório evita recomendar como ausente o que já aparece no repositório: há uso de `flake-parts` em `flake.nix`, `disko` para `vps-server`, `sops-nix`, Podman/OCI, módulos próprios, templates e algum hardening de systemd.

## Estado atual observado

- O flake já usa `flake-parts` como input (`flake.nix`) e constrói `nixosConfigurations` via `lib.mapAttrs mkSystem hosts`; portanto **não** faz sentido vender “migrar para flake-parts” como melhoria.
- Há substituters/Cachix configurados no `nixConfig` (`flake.nix`) para nix-community, COSMIC e agent-of-empires.
- Há `sops-nix` global e segredos declarados em `hosts/configuration.nix`; o README documenta token GitHub com `!include` em `nix.extraOptions`.
- Há `disko` como input e uso concreto em `hosts/vps-server/disk-config.nix`; não é ausente, mas está restrito ao VPS.
- Há Podman/OCI em `hosts/configuration.nix`, `hosts/b450/default.nix`, `modules/home-automation/default.nix`, `modules/home-automation/frigate/default.nix` e `modules/twingate.nix`.
- Há imagens OCI parcialmente versionadas (`twingate/connector:1.78`, `docker.io/twingate/connector:1.91`, `ghcr.io/home-assistant/home-assistant:2026.3`, `ghcr.io/blakeblackshear/frigate:0.17.0`) e também tags mutáveis (`searxng/searxng:latest`, `nodered/node-red`, `docker.io/koenkk/zigbee2mqtt:latest`, `docker.io/eclipse-mosquitto`).
- Há hardening explícito em alguns serviços: `ProtectSystem = "strict"` em `modules/servers/hermes-agent-gateway.nix`, `modules/servers/nostr-sync-relay.nix` e comentário específico em `hosts/n100/default.nix`; portanto a recomendação deve ser ampliar seletivamente, não “adicionar hardening” genericamente.
- Há template com `checks` no `templates/bevy/flake.nix`, mas no flake principal não foi encontrada saída `checks`, `formatter` ou integração `treefmt-nix`.
- Não foi encontrada configuração de CI em `.github/workflows` nesta cópia, nem `deploy-rs`, nem `nixos-anywhere`, nem `lanzaboote`, nem `impermanence`, nem `restic`.

## Priorização resumida

| Prioridade | Proposta | Impacto | Esforço | Risco |
|---|---|---:|---:|---:|
| P0 | Adicionar `checks` do flake principal para avaliação/build de hosts e pacotes críticos | Alto | Médio | Baixo/Médio |
| P0 | Padronizar formatação com `treefmt-nix` e expor `formatter` | Médio | Baixo | Baixo |
| P0 | Fixar imagens OCI por digest e remover tags mutáveis | Alto | Baixo/Médio | Médio |
| P1 | CI com `nix flake check`, cache binário e checks seletivos por host | Alto | Médio | Médio |
| P1 | Ampliar hardening systemd com auditoria por serviço | Alto | Médio | Médio |
| P1 | Backups declarativos com `services.restic.backups` para estado persistente | Alto | Médio | Médio |
| P2 | Expansão controlada de `disko` e instalação remota com `nixos-anywhere` | Médio/Alto | Médio | Alto |
| P2 | Deploy declarativo com `deploy-rs` ou fluxo documentado de `nixos-rebuild` remoto | Médio | Médio | Médio |
| P2 | Secure Boot com Lanzaboote em máquinas adequadas | Médio/Alto | Médio | Alto |
| P3 | Testes NixOS VM para módulos próprios | Médio | Médio/Alto | Baixo/Médio |
| P3 | Impermanence para hosts descartáveis/servidores | Médio | Alto | Alto |

## Quick wins

### 1. `checks` mínimos no flake principal

**Evidência local.** O flake monta hosts em `flake.nix` via `nixosConfigurations = lib.mapAttrs mkSystem hosts;`, e há `checks` apenas dentro de template (`templates/bevy/flake.nix`). Isso deixa o repositório sem uma prova padrão de que os hosts principais ainda avaliam.

**Recomendação.** Expor checks leves por sistema, começando por avaliação/toplevel dos hosts mais importantes e pacotes locais críticos. Exemplo conceitual em `perSystem`/outputs do flake atual:

```nix
checks.${system}.nixos-n100 = self.nixosConfigurations.n100.config.system.build.toplevel;
checks.${system}.nixos-vps-server = self.nixosConfigurations.vps-server.config.system.build.toplevel;
```

Para hosts pesados, separar checks “eval only” e builds reais por CI agendado. A documentação oficial de flakes define a saída `checks` como derivations executadas por `nix flake check` e a saída `formatter` como formatador usado por `nix fmt` ([Nix manual: Flake output attributes](https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake#flake-output-attributes); [nix flake check](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-check)).

- Impacto: alto, porque detecta regressões antes de rebuild remoto.
- Esforço: médio, por causa de hosts com inputs privados e builds grandes.
- Risco: baixo/médio; o principal risco é CI tentar compilar artefatos caros.

### 2. `treefmt-nix` e `formatter`

**Evidência local.** Há configuração de formatação no editor (`modules/editors/helix.nix` usa `alejandra` e `shfmt`), mas não há `treefmt.nix`, input `treefmt-nix` ou `formatter` no flake principal.

**Recomendação.** Adicionar `treefmt-nix` para Nix, Shell e Markdown, e expor `formatter.${system}`. Isso transforma a preferência do editor em contrato do repositório (`nix fmt`/CI). Fonte primária: o repositório oficial `numtide/treefmt-nix` documenta o módulo flake-parts e integração com `formatter`/checks ([treefmt-nix](https://github.com/numtide/treefmt-nix)).

- Impacto: médio, reduz ruído em revisões e facilita contribuição.
- Esforço: baixo.
- Risco: baixo; aplicar em PR separado para evitar diff grande.

### 3. Imagens OCI por digest e política de atualização

**Evidência local.** Em `hosts/b450/default.nix`, `searxng/searxng:latest` é mutável; em `modules/home-automation/default.nix`, `nodered/node-red`, `docker.io/koenkk/zigbee2mqtt:latest` e `docker.io/eclipse-mosquitto` também são mutáveis. Ao mesmo tempo, alguns serviços já têm tags versionadas, como Frigate em `modules/home-automation/frigate/default.nix`.

**Recomendação.** Pin por digest (`image = "repo/name@sha256:..."`) para serviços críticos e documentar rotina de atualização. A opção NixOS `virtualisation.oci-containers.containers.<name>.image` aceita a referência de imagem entregue ao backend OCI, e Podman/Docker aceitam referências por digest; a documentação oficial de Podman descreve imagens e health checks em `podman-run`/`podman-healthcheck` ([NixOS options: oci-containers](https://search.nixos.org/options?query=virtualisation.oci-containers.containers); [Podman run reference](https://docs.podman.io/en/latest/markdown/podman-run.1.html); [Podman healthcheck](https://docs.podman.io/en/latest/markdown/podman-healthcheck.1.html)).

- Impacto: alto, especialmente para automação residencial e túneis.
- Esforço: baixo/médio.
- Risco: médio; digest errado quebra pull, então testar por serviço.

## Melhorias estruturais

### 4. CI com cache binário e checks seletivos

**Evidência local.** `flake.nix` já declara substituters e chaves Cachix; não há workflow `.github/workflows` nesta cópia. Há comentários em `flake.nix` sobre evitar builds pesados do `agent-of-empires` no n100 usando o cache upstream, o que torna cache/CI ainda mais relevante.

**Recomendação.** Criar CI que rode `nix flake check --accept-flake-config` e, em branches principais, checks de hosts selecionados. Usar Cachix Action ou outro cache oficial apenas com chaves via secrets do GitHub, nunca no repositório. Fontes primárias: `nix flake check` no manual Nix; repositório oficial `cachix/cachix-action`; documentação oficial do GitHub Actions para secrets ([Nix flake check](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-check); [cachix-action](https://github.com/cachix/cachix-action); [GitHub encrypted secrets](https://docs.github.com/actions/security-guides/encrypted-secrets)).

- Impacto: alto.
- Esforço: médio, por inputs privados (`README.md` já documenta token GitHub para flakes privados).
- Risco: médio por vazamento acidental de tokens se não usar secrets.

### 5. Hardening systemd por perfil de serviço

**Evidência local.** Já há hardening em `modules/servers/hermes-agent-gateway.nix` e `modules/servers/nostr-sync-relay.nix` com `ProtectSystem = "strict"`; em `hosts/n100/default.nix` há comentário avisando que `DynamicUser = false` é necessário para ler GGUFs privados, então uma regra genérica quebraria o serviço.

**Recomendação.** Criar um módulo/fragmento reutilizável para serviços próprios com defaults seguros, mas com opt-out explícito por serviço: `NoNewPrivileges`, `PrivateTmp`, `ProtectHome`, `ProtectSystem`, `RestrictAddressFamilies`, `SystemCallFilter`, `CapabilityBoundingSet`, `ReadWritePaths`. Validar com `systemd-analyze security <unit>`. Fontes primárias: manuais oficiais do systemd para `systemd.exec` e `systemd-analyze security` ([systemd.exec](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html); [systemd-analyze](https://www.freedesktop.org/software/systemd/man/latest/systemd-analyze.html)).

- Impacto: alto para serviços expostos (`n100`, cloudflared, gateways, home automation).
- Esforço: médio.
- Risco: médio; pode bloquear acesso a arquivos/AFs necessários.

### 6. Backups declarativos com Restic

**Evidência local.** Não foi encontrado `restic` no repositório. Há estado relevante: banco em `data/aionui-backend.db*`, diretórios de automação residencial em módulos, segredos SOPS e serviços no `n100`/VPS.

**Recomendação.** Introduzir `services.restic.backups` por host, começando por dados que não derivam do Nix: bancos, volumes de containers, configurações runtime e home automation. Guardar senha/repositório via `sops-nix`. Fonte primária: opções oficiais do NixOS para `services.restic.backups` e documentação oficial do Restic ([NixOS options: restic](https://search.nixos.org/options?query=services.restic.backups); [Restic documentation](https://restic.readthedocs.io/en/stable/)).

- Impacto: alto.
- Esforço: médio.
- Risco: médio; backup sem restore testado dá falsa segurança.

### 7. Deploy remoto: escolher entre fluxo simples e `deploy-rs`

**Evidência local.** Existem scripts manuais (`scripts/deploy-n100.sh`, `scripts/install-arm.sh`) e README com `sudo nixos-rebuild switch --flake .#<host> --impure`; não foi encontrado `deploy-rs`.

**Recomendação.** Se o fluxo atual for suficiente, documentar `nixos-rebuild --target-host`/`--build-host` e pré-checagens. Se houver múltiplos hosts e necessidade de rollback/orquestração, adicionar `deploy-rs` com nós `n100` e `vps-server`. Fontes primárias: manual NixOS/nixos-rebuild e repositório oficial `serokell/deploy-rs` ([NixOS manual: changing configuration / nixos-rebuild](https://nixos.org/manual/nixos/stable/#sec-changing-config); [deploy-rs](https://github.com/serokell/deploy-rs)).

- Impacto: médio.
- Esforço: médio.
- Risco: médio; deploy automatizado ruim derruba host remoto.

## Funcionalidades novas

### 8. Expandir `disko` e considerar `nixos-anywhere` para instalação reproduzível

**Evidência local.** `disko` já é input e `hosts/vps-server/disk-config.nix` já declara particionamento do VPS; desktops e `n100` ainda usam `hardware-configuration.nix` tradicional.

**Recomendação.** Não “adicionar disko” genericamente; ele já existe. A melhoria é expandir gradualmente para hosts novos ou reinstaláveis, e combinar com `nixos-anywhere` apenas onde reinstalação remota for aceitável. Fontes primárias: repositórios oficiais `nix-community/disko` e `nix-community/nixos-anywhere` ([disko](https://github.com/nix-community/disko); [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)).

- Impacto: médio/alto para recuperação e bootstrap.
- Esforço: médio.
- Risco: alto; erros de layout destroem dados.

### 9. Secure Boot com Lanzaboote

**Evidência local.** Não foi encontrado `lanzaboote`/Secure Boot. `hosts/vps-server/default.nix` usa GRUB; laptops/desktops têm boot em arquivos próprios.

**Recomendação.** Avaliar Lanzaboote primeiro em uma máquina física com console local e rollback fácil, não no VPS. Fonte primária: repositório oficial `nix-community/lanzaboote`, que integra Secure Boot ao NixOS usando systemd-boot e sbctl ([Lanzaboote](https://github.com/nix-community/lanzaboote); [NixOS manual: systemd-boot](https://nixos.org/manual/nixos/stable/#sec-boot-loader-systemd-boot)).

- Impacto: médio/alto para laptops.
- Esforço: médio.
- Risco: alto; configuração errada pode impedir boot.

### 10. Testes NixOS VM para módulos próprios

**Evidência local.** `hosts/thinkpad/router/default.nix` importa `./checks.nix`, mas não foi visto conjunto principal de `nixosTests` para módulos como `cloudflared-connector`, `hermes-agent-gateway`, `nostr-sync-relay` ou automação residencial.

**Recomendação.** Criar testes VM pequenos para módulos próprios que têm lógica: verificar que options geram units esperadas, secrets são referenciados por caminho e portas/serviços sobem. Fonte primária: seção oficial do manual NixOS sobre testes baseados em VM/Python ([NixOS manual: NixOS tests](https://nixos.org/manual/nixos/stable/#sec-nixos-tests)).

- Impacto: médio.
- Esforço: médio/alto.
- Risco: baixo/médio; testes podem ficar caros se incluírem serviços pesados.

### 11. Impermanence em hosts apropriados

**Evidência local.** Não foi encontrado `impermanence`. Há dados persistentes e segredos, então isso não deve ser aplicado sem inventário.

**Recomendação.** Considerar `impermanence` apenas para servidores/hosts onde root efêmero traga valor operacional. Antes, listar persistências obrigatórias: `/var/lib`, volumes Podman, bancos, `/etc/ssh`, segredos age/sops, NetworkManager etc. Fonte primária: repositório oficial `nix-community/impermanence` ([impermanence](https://github.com/nix-community/impermanence)).

- Impacto: médio para higiene e rollback.
- Esforço: alto.
- Risco: alto; persistência incompleta causa perda de estado.

## Recomendações que eu evitaria agora

- **Migrar para flake-parts**: o input já existe em `flake.nix`; se houver melhoria, é completar a organização atual, não migrar.
- **Trocar SOPS por outra solução**: `sops-nix` está integrado em `flake.nix`, `hosts/configuration.nix` e README. Melhorar rotação/documentação é mais útil que substituir.
- **Adicionar disko como novidade global**: já existe para `vps-server`; a proposta correta é expansão seletiva.
- **Hardening genérico sem inventário**: comentários em `hosts/n100/default.nix` mostram exceções reais (`DynamicUser = false` por necessidade de acesso a modelos privados).

## Sequência sugerida de implementação

1. Adicionar `treefmt-nix` + `formatter` + CI simples que rode `nix fmt -- --ci`/`treefmt --ci` e `nix flake check` com escopo leve.
2. Adicionar `checks` do flake principal para avaliação/build de `vps-server` e um host desktop representativo, depois ampliar.
3. Pin de imagens OCI por digest nos serviços com tags mutáveis e adicionar health checks Podman onde o serviço expõe endpoint claro.
4. Criar política de backups Restic por host, com um teste de restore documentado.
5. Auditar hardening systemd serviço a serviço com `systemd-analyze security`.
6. Só depois avaliar deploy-rs/nixos-anywhere/Lanzaboote/impermanence, porque têm maior risco operacional.

## Evidência de verificação deste relatório

- Caminhos concretos citados acima foram obtidos por inspeção local de `flake.nix`, `hosts/`, `modules/`, `templates/`, `scripts/` e `README.md`.
- As recomendações principais citam fontes primárias: manuais oficiais Nix/NixOS/systemd/Podman/Restic/GitHub e repositórios oficiais dos projetos recomendados.
- Cada proposta inclui impacto, esforço e risco, e o texto marca explicitamente o que já está implementado para evitar duplicidade.
