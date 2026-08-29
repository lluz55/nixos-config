# Nostr Sync Relay (dl_bestfin)

Relay Nostr local (binário `strfry`, rodando sob a unit systemd própria
`bestfin_syncd` -- não o módulo genérico `services.strfry` do nixpkgs, que
fixa o nome da unit como `strfry.service`) para a sync E2E do app
[dl_bestfin](https://github.com/) na rede local, como alternativa/complemento
aos relays públicos padrão do app.

## Contexto

O dl_bestfin sincroniza dados financeiros cifrados (AES-256-GCM) entre
dispositivos do mesmo household publicando eventos Nostr `kind:30078`
(NIP-78) — ver `docs/okf/features/sync.md` no repo do app. A arquitetura é
serverless por padrão: usa ~10 relays públicos de terceiros
(`defaultRelays`), com a lista de relays configurável por dispositivo em
**Sincronização > Relays** no app.

Este módulo hospeda um relay adicional no n100, para os dispositivos do
household sincronizarem entre si direto na rede local (mais rápido, sem
depender de internet), sem exigir nenhuma mudança no app: o cliente já
aceita relays `ws://` explícitos (não força TLS quando o esquema é
informado — ver `normalizeRelayUrl` em
`lib/features/sync/data/services/nostr_sync_service.dart`) e já expõe a
pubkey hex completa (toque para copiar) em **Sincronização > Identidade**.

## Arquivos envolvidos

- Módulo: `modules/servers/nostr-sync-relay.nix`
- Host habilitado: `hosts/n100/default.nix` (`services.nostrSyncRelay`)
- Sem segredos (é chave pública) — `authorizedPubkeys` fica em texto puro no
  próprio host, mesmo padrão do `authorizedNpubs` em
  `hosts/n100/dl-conn-config.yaml`.

## Como funciona

- `services.nostrSyncRelay.enable = true` sobe a unit systemd `bestfin_syncd`
  (usuário/grupo de sistema `bestfin_syncd`, dados em
  `/var/lib/bestfin_syncd`), executando o binário `strfry` com:
  - `relay.bind`/`relay.port` (padrão `0.0.0.0:7777`);
  - `relay.writePolicy.plugin` apontando para um script Python gerado em
    build time, que só aceita (`EVENT`) publicações cujo `pubkey` esteja em
    `authorizedPubkeys`. Leitura (`REQ`) não é filtrada — o cliente já
    restringe o pull por `authors` na query.
- Sem mudança de firewall: o n100 não usa `networking.firewall` (está
  desabilitado em `hosts/n100/router/networking.nix` em favor de um
  ruleset nftables próprio), e esse ruleset já aceita tudo vindo de
  `br-lan`/`br-cams`/`vl-mgmt`/`vl-home` para o próprio host, sem abrir
  nada novo para a WAN. Bind em `0.0.0.0` portanto só fica alcançável pelas
  VLANs já confiáveis.

## Configuração atual (n100)

```nix
services.nostrSyncRelay = {
  enable = true;
  authorizedPubkeys = [
    "<hex de 64 chars>"
  ];
};
```

## Passo a passo para habilitar

1. **Obter a pubkey hex do household**
   - No app dl_bestfin, abra **Sincronização** > seção **Identidade**.
   - Toque na chave truncada (ex.: `a1b2c3d4...e5f6a7b8`) — o hex completo
     (64 chars) é copiado para a área de transferência.

2. **Preencher `authorizedPubkeys`**
   - Em `hosts/n100/default.nix`, cole o hex dentro da lista
     `services.nostrSyncRelay.authorizedPubkeys`.
   - O módulo tem uma assertion: `nixos-rebuild` falha se a lista estiver
     vazia com `enable = true`.

3. **Aplicar no host**
   ```bash
   sudo nixos-rebuild switch --flake .#n100 --impure
   sudo systemctl status bestfin_syncd
   sudo journalctl -u bestfin_syncd -n 50 --no-pager
   ```

4. **Adicionar o relay em cada dispositivo do household**
   - No app: **Sincronização > Relays** > adicionar relay.
   - URL: `ws://<ip-do-n100-na-rede-do-dispositivo>:7777`
     - Rede `br-lan` (padrão): `ws://192.168.1.1:7777`
     - Rede `vl-home`: `ws://10.0.55.1:7777`
   - Use `ws://` explícito (não deixe o app inferir o esquema — sem isso
     ele assume `wss://`, que exige TLS e não é o caso deste relay local).
   - Repita em todos os dispositivos do mesmo household — os relays
     custom são persistidos por dispositivo (`SharedPreferences`), não
     sincronizados entre eles.

5. **Validar**
   - Com os dois dispositivos na mesma rede e o relay novo adicionado,
     force um sync (botão "Sincronizar agora") em cada um e confira nos
     logs (`journalctl -u bestfin_syncd -f`) se os eventos aparecem.
   - Publicar de uma pubkey fora de `authorizedPubkeys` deve resultar em
     `reject` (visível no log do relay, e o app deve ignorar silenciosamente
     esse relay para aquele evento, já que outros relays da lista tendem a
     aceitar).

## Como adicionar outro household (múltiplas pubkeys)

```nix
services.nostrSyncRelay = {
  enable = true;
  authorizedPubkeys = [
    "<hex household 1>"
    "<hex household 2>"
  ];
};
```

## Comandos úteis

```bash
# Ver o ExecStart efetivo da unit (mostra o path do strfry e do config.json no /nix/store)
systemctl cat bestfin_syncd

# Inspecionar os eventos armazenados direto no LMDB, sem precisar do app --
# extrai o path do config.json direto da unit em execução
CONFIG=$(systemctl show bestfin_syncd -p ExecStart --value | grep -oP -- '--config=\K\S+')
sudo -u bestfin_syncd strfry --config="$CONFIG" scan '{}'

# Testar o write-policy manualmente (fora do systemd) -- reusa o $CONFIG acima
PLUGIN=$(jq -r '.relay.writePolicy.plugin' "$CONFIG")
echo '{"event":{"id":"deadbeef","pubkey":"<hex nao autorizado>"}}' | "$PLUGIN"
```
