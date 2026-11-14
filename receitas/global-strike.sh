#!/usr/bin/env bash
set -euo pipefail

: "${RAIZ:?Defina RAIZ como o diretório do repositório}"
: "${SAIDA:?Defina SAIDA como o diretório de saída}"

# Não há CMakeLists.txt, configure.ac, meson.build ou Makefile:
# o jogo é um build web pré-compilado em assets/
for arquivo in index.html servers.json; do
  [[ -f "$RAIZ/$arquivo" ]] || {
    echo "ERRO: arquivo obrigatório não encontrado: $RAIZ/$arquivo" >&2
    exit 1
  }
done

[[ -d "$RAIZ/assets" ]] || {
  echo "ERRO: diretório obrigatório não encontrado: $RAIZ/assets" >&2
  exit 1
}

mkdir -p "$SAIDA"
cp "$RAIZ/index.html" "$RAIZ/servers.json" "$SAIDA/"
cp -a "$RAIZ/assets" "$SAIDA/"

echo "Cliente web do Global-Strike preparado em: $SAIDA"
