# Scripts

Scripts auxiliares para configurar o Waydroid com suporte a Magisk, Zygisk Next,
Play Integrity Fix e traducao ARM em hosts NixOS.

## Pre-requisitos

- Waydroid instalado e inicializado.
- Acesso a `sudo`.
- Rede disponivel para baixar releases do GitHub quando necessario.
- Nix/NixOS disponivel no host.

Alguns scripts precisam rodar como usuario normal e chamam `sudo` internamente.
Outros precisam ser executados diretamente como root. Veja a tabela abaixo.

## Scripts disponiveis

| Script | Executar como | Funcao |
| --- | --- | --- |
| `install-magisk.sh` | usuario normal | Compila o pacote `waydroidsu` via Nix e executa `wsu install` com `sudo` para instalar WaydroidSU/Magisk no Waydroid. |
| `install-zygisk-next.sh` | usuario normal | Baixa a ultima release do Zygisk Next, ajusta o perfil seccomp do Waydroid quando necessario e instala o modulo via Magisk. |
| `install-play-integrity-fix.sh` | usuario normal | Baixa a ultima release do Play Integrity Fix e instala o modulo via Magisk no Waydroid. |
| `install-arm.sh` | root/sudo | Instala suporte de traducao ARM no Waydroid usando `casualsnek/waydroid_script`. |

## Ordem recomendada

```bash
./scripts/install-magisk.sh
./scripts/install-zygisk-next.sh
./scripts/install-play-integrity-fix.sh
sudo ./scripts/install-arm.sh
```

Depois de instalar modulos do Magisk, reinicie o container:

```bash
sudo systemctl restart waydroid-container.service
```

## `install-magisk.sh`

Compila o pacote `waydroidsu` definido neste flake e executa o instalador:

```bash
./scripts/install-magisk.sh
```

Argumentos adicionais sao repassados para `wsu install`:

```bash
./scripts/install-magisk.sh <argumentos>
```

O script deve ser chamado como usuario normal. Ele usa `sudo` apenas para a etapa
que precisa instalar o WaydroidSU/Magisk.

## `install-zygisk-next.sh`

Instala o Zygisk Next como modulo do Magisk:

```bash
./scripts/install-zygisk-next.sh
```

O script:

- verifica se o container do Waydroid esta rodando e tenta inicia-lo;
- remove a restricao `reboot` do perfil seccomp de Waydroid quando ela existe;
- cria backup do seccomp em `/var/lib/waydroid/lxc/waydroid/waydroid.seccomp.bak`;
- baixa a ultima release de `Dr-TSNG/ZygiskNext`;
- copia o zip para `/data/local/tmp` dentro do Waydroid;
- instala o modulo com `magisk --install-module`.

Apos a instalacao, abra o app Magisk dentro do Waydroid e deixe o Zygisk nativo
do Magisk desativado. O Zygisk Next roda separadamente.

## `install-play-integrity-fix.sh`

Instala o Play Integrity Fix como modulo do Magisk:

```bash
./scripts/install-play-integrity-fix.sh
```

O script:

- verifica se o container do Waydroid esta rodando e tenta inicia-lo;
- baixa a ultima release de `osm0sis/PlayIntegrityFork`;
- copia o zip para `/data/local/tmp` dentro do Waydroid;
- instala o modulo com `magisk --install-module`;
- remove os arquivos temporarios ao final.

Magisk precisa estar instalado e funcional antes de executar este script.

## `install-arm.sh`

Instala uma camada de traducao ARM usando `casualsnek/waydroid_script`.

Uso com deteccao automatica:

```bash
sudo ./scripts/install-arm.sh
```

Por padrao, o script usa:

- `libndk` em CPUs AMD;
- `libhoudini` nos demais casos.

Tambem e possivel escolher explicitamente:

```bash
sudo ./scripts/install-arm.sh libhoudini
sudo ./scripts/install-arm.sh libndk
```

O script clona `casualsnek/waydroid_script` em um diretorio temporario, cria um
ambiente Python e executa `python3 main.py install <libhoudini|libndk>`.

## Solucao de problemas

- Se a instalacao de Zygisk Next ou Play Integrity Fix falhar, confirme que o
  Magisk foi instalado com `./scripts/install-magisk.sh`.
- Se o Waydroid nao iniciar, confira o status com:

```bash
waydroid status
sudo systemctl status waydroid-container.service
```

- Se o GitHub bloquear ou limitar requisicoes, tente novamente mais tarde ou
  baixe o modulo manualmente.
