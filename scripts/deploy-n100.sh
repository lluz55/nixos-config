#!/usr/bin/env bash
# deploy-n100.sh — rebuild do n100 usando o checkout LOCAL do dl_home_control.
#
# Por que existe: `lluz55/dl_home_control` é um repositório privado e o Nix
# busca inputs do GitHub sem autenticação, então a avaliação falha com um 404
# que se parece com "commit não existe". Em vez de guardar um token no
# nix.conf, o deploy aponta o input para a árvore local via --override-input:
# a avaliação e o build acontecem aqui e só a closure viaja por SSH.
#
# O preço, consciente: o que vai para a máquina NÃO fica registrado no
# flake.lock. Para um deploy reproduzível/auditável, publique o commit e use
# `nix flake update dl-home-control` com credencial — ver README.
set -euo pipefail

DLHC_SRC="${DLHC_SRC:-$HOME/dev/dl_home_control}"
TARGET="${TARGET:-lluz@10.0.66.1}"
ACTION="${1:-switch}"

if [ ! -e "$DLHC_SRC/flake.nix" ]; then
  echo "erro: $DLHC_SRC não parece um checkout do dl_home_control" >&2
  echo "      defina DLHC_SRC=/caminho/do/checkout" >&2
  exit 1
fi

# Commit não publicado vira máquina rodando código que não existe em lugar
# nenhum além deste disco — avisa, mas não bloqueia (o modo local existe
# justamente para iterar antes de publicar).
if ! git -C "$DLHC_SRC" diff --quiet || ! git -C "$DLHC_SRC" diff --cached --quiet; then
  echo "aviso: $DLHC_SRC tem mudanças não commitadas — elas vão para o n100" >&2
fi

# A armadilha silenciosa: o Nix avalia a ÁRVORE DO GIT, então arquivo novo
# ainda não rastreado fica de fora do build sem erro nenhum. O sintoma
# aparece longe daqui (pacote/símbolo "não existe") e nunca aponta para o
# git. `git add -N` basta para incluí-lo.
if [ -n "$(git -C "$DLHC_SRC" ls-files --others --exclude-standard)" ]; then
  echo "aviso: $DLHC_SRC tem arquivos NÃO RASTREADOS — o Nix os ignora:" >&2
  git -C "$DLHC_SRC" ls-files --others --exclude-standard | sed 's/^/       /' >&2
  echo "       use 'git add -N <arquivo>' se algum deles for necessário ao build" >&2
fi

cd "$(dirname "${BASH_SOURCE[0]}")/.."
exec nixos-rebuild "$ACTION" \
  --flake ".#n100" \
  --target-host "$TARGET" \
  --elevate=sudo \
  --override-input dl-home-control "$DLHC_SRC"
