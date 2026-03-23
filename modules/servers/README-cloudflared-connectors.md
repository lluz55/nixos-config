# Cloudflared Connectors (Multi-Tunnel)

Este módulo adiciona suporte a múltiplos túneis `cloudflared` com segredos via `sops-nix`.

## Arquivos envolvidos

- Módulo: `modules/servers/cloudflared-connector.nix`
- Host habilitado: `hosts/n100/default.nix`
- Segredos: `secrets/secrets.yaml`

## Como funciona

- Cada túnel em `cloudflaredConnectors.tunnels` gera:
  - 1 segredo em `sops.secrets` (token)
  - 1 serviço systemd: `cloudflared-connector-<nome>`
- Base de domínio vem do segredo SOPS:
  - chave SOPS-Nix: `cloudflare/tunnels/domain_base`
  - YAML: `cloudflare.tunnels.domain_base`
  - Exemplo atual: `domain.com.br`
- Hostname efetivo por túnel: `<nome>.<domain_base>`
  - Exemplo atual: `ssh.domain.com.br`

## Configuração atual (n100)

```nix
cloudflaredConnectors = {
  enable = true;
  tunnels = {
    ssh = { };
  };
};
```

## Estrutura de segredo (SOPS)

O túnel `ssh` usa por padrão:

- chave SOPS-Nix: `cloudflare/tunnels/ssh/token`
- caminho no YAML: `cloudflare.tunnels.ssh.token`
- base de domínio (global): `cloudflare.tunnels.domain_base`

Exemplo em `secrets/secrets.yaml`:

```yaml
cloudflare:
  tunnels:
    domain_base: ENC[...]
    ssh:
      token: ENC[...]
```

## Como adicionar outro túnel (passo a passo)

Exemplo: adicionar um túnel chamado `git` com hostname `git.example.net`.

1. Criar o túnel no Cloudflare Zero Trust
- Crie o tunnel com nome `git`.
- Em Public Hostname, configure:
  - Hostname: `git.example.net`
  - Service: o endereço interno que esse túnel deve alcançar (ex.: `ssh://localhost:22` ou `http://localhost:3000`).
- Copie o token desse túnel.

2. Salvar o token no `sops`
```bash
sops --set '["cloudflare"]["tunnels"]["git"]["token"] "TOKEN_DO_TUNEL_GIT"' secrets/secrets.yaml
```

3. Garantir base de domínio no `sops`
- O módulo usa a chave `cloudflare.tunnels.domain_base`.
- Exemplo de valor:
```bash
sops --set '["cloudflare"]["tunnels"]["domain_base"] "example.net"' secrets/secrets.yaml
```

4. Declarar o túnel no host
- Em `hosts/n100/default.nix`, adicione `git = { };`:
```nix
cloudflaredConnectors = {
  enable = true;
  tunnels = {
    ssh = { };
    git = { };
  };
};
```

5. Aplicar e validar
```bash
sudo nixos-rebuild switch --flake .#n100 --impure
sudo systemctl status cloudflared-connector-git
sudo journalctl -u cloudflared-connector-git -n 50 --no-pager
```

Resultado esperado:
- serviço `cloudflared-connector-git` em execução;
- token lido de `cloudflare/tunnels/git/token`;
- hostname efetivo seguindo `<nome>.<domain_base>` (`git.example.net` neste exemplo).

## Comandos úteis

Validar serviço gerado:

```bash
nix eval --raw .#nixosConfigurations.n100.config.systemd.services.cloudflared-connector-ssh.serviceConfig.ExecStart
```

Aplicar no host:

```bash
sudo nixos-rebuild switch --flake .#n100 --impure
```

## Uso no cliente (SSH remoto)

No cliente (seu notebook/desktop), instale `cloudflared` e rode:

```bash
ssh -o ProxyCommand="cloudflared access ssh --hostname %h" <usuario>@<url-cloudflare>
```

Se seu túnel no Cloudflare estiver com outro domínio (por exemplo `ssh.dominio.com.br`), use esse hostname no comando.

### Checklist rápido no cliente

- `cloudflared` instalado no cliente
- usuário/autenticação permitidos na política do Cloudflare Access
- hostname do comando igual ao hostname configurado no Tunnel/Zero Trust
- SSH ativo no host de destino (neste caso, `localhost:22` no `n100`)
