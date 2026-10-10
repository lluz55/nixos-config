# Auditoria NixOS — melhorias necessárias

Data da auditoria: 2026-10-09

## Escopo

Este documento consolida as melhorias identificadas na configuração dos hosts
`n100`, `b450`, `s14`, `gl62m`, `thinkpad` e `vps-server`.

Não contém credenciais nem valores secretos. Segredos devem permanecer em
`secrets/secrets.yaml`, criptografados com SOPS.

## Prioridade crítica

- [ ] Remover a senha inicial estática do 9Router e injetá-la por arquivo SOPS.
- [ ] Colocar Pi Web e outros painéis capazes de executar agentes somente em
      loopback ou atrás de proxy/VPN com autenticação forte.
- [ ] Migrar o hash de senha do usuário do VPS para `hashedPasswordFile` via
      SOPS e rotacionar a senha.
- [ ] Migrar a credencial do modo `camera-router` do ThinkPad para SOPS e
      rotacioná-la.
- [ ] Remover do histórico Git material sensível que já tenha sido commitado.
      Retirar do índice atual não apaga commits antigos.
- [ ] Revisar e rotacionar a credencial MQTT cujo hash já esteve versionado.

## Segurança de serviços

- [ ] Aplicar hardening gradual aos serviços 9Router, Pi Web, Agent of Empires,
      DSH e OmniRoute: usuário dedicado quando possível, `NoNewPrivileges`,
      `ProtectSystem`, `ProtectHome`, `PrivateTmp`, `PrivateDevices` e acesso
      explícito somente aos diretórios necessários.
- [ ] Reduzir os privilégios dos containers de automação, especialmente Frigate:
      substituir `--privileged` e `CAP_ALL` por dispositivos e capabilities
      mínimos após testes de Coral/VAAPI.
- [ ] Fixar tags ou digests das imagens OCI. Evitar `latest` e imagens sem tag.
- [ ] Revisar a regra Polkit que autoriza incondicionalmente membros de `wheel`.
- [ ] Documentar a finalidade de cada porta aberta no firewall do `b450` e
      remover portas sem consumidor confirmado.
- [ ] Restringir por interface/sub-rede serviços que não precisam ficar
      disponíveis em toda a LAN.

## Confiabilidade

- [ ] Corrigir a avaliação da especialização `camera-router` do ThinkPad. A
      configuração usa `lib.mkForce` em `sops.secrets` e remove a declaração
      global necessária ao template de token GitHub.
- [ ] Resolver o aviso de interface Wi-Fi configurada simultaneamente como
      cliente e access point na especialização do ThinkPad.
- [ ] Declarar explicitamente OpenSSH, autenticação somente por chave e
      Fail2ban no `vps-server`; hoje ele não herda a baseline dos demais hosts.
- [ ] Substituir wrappers que resolvem pacotes em runtime via `uvx` por pacotes
      versionados/lockados quando forem usados como serviços permanentes.
- [ ] Remover ou arquivar fora da raiz o `error.txt` histórico.
- [ ] Evitar dependência impura de `/home/lluz/dev/dl_home_control` na avaliação
      normal; usar input fixado ou override somente no fluxo de desenvolvimento.

## Organização e redução de software

- [x] Definir Home Manager como camada para software pessoal/interativo e NixOS
      como camada para serviços, hardware, firewall, containers e administração.
- [x] Remover de `modules/default.nix` ferramentas pessoais já geridas pelo Home
      Manager: Claude Code, Antigravity CLI, Neovim, Helix, Ripgrep, Zoxide, SD,
      Broot, Dust, GitHub CLI, Lazygit, Nmap, Nil e Lua Language Server.
- [x] Remover Rustup do perfil NixOS, mantendo a versão do Home Manager.
- [ ] Consolidar os cinco navegadores atuais e manter apenas os realmente usados.
- [ ] Dividir o perfil desktop em perfis menores: base, desenvolvimento, IA,
      gaming, virtualização, impressão, NVIDIA e laptop.
- [ ] Separar agentes estáveis de agentes experimentais e evitar instalar todos
      em todos os desktops.
- [ ] Consolidar a configuração repetida de Agent of Empires/Pi Web entre
      `n100` e `s14`.

## Rede e serviços removidos nesta etapa

- [x] Remover Tailscale da configuração.
- [x] Remover Netbird da configuração.
- [x] Remover os conectores Cloudflare Tunnel declarativos.
- [x] Remover o `dl-conn`: a versão fixada sempre inicia `cloudflared` e não
      permite manter somente a sinalização Nostr sem o túnel.
- [x] Remover os containers Home Assistant e Node-RED.
- [x] Remover rotas e regras DNAT específicas desses dois serviços.

## Higiene do repositório

- [x] Ignorar bancos, WAL/SHM, logs, caches, backups e estados de runtime da
      automação residencial.
- [x] Retirar do índice Git, sem apagar do disco, banco/logs/estado do Mosquitto,
      backup redundante do Frigate e artefatos de runtime já rastreados.
- [ ] Manter no Git somente configuração sanitizada e exemplos sem credenciais.
- [ ] Considerar mover dados persistentes de automação para `/var/lib` ou outro
      diretório de estado fora do checkout da configuração NixOS.

## Validação esperada antes de implantação

1. Executar `nix flake show --no-write-lock-file`.
2. Avaliar o `drvPath` de todos os hosts.
3. Executar build sem ativação para os hosts afetados, especialmente `n100`.
4. Confirmar que não existem units Tailscale, Netbird, Cloudflared, Home
   Assistant ou Node-RED na nova geração.
5. Confirmar Zigbee2MQTT e Mosquitto antes de aplicar `switch`.
6. Aplicar em janela de manutenção e validar nftables, DNS/DHCP, Frigate,
   Zigbee2MQTT, MQTT e os serviços publicados pelo `dl-conn`.
