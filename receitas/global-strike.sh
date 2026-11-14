#!/usr/bin/env bash
set -euo pipefail

: "${RAIZ:?Defina RAIZ como o diretório do repositório}"
: "${SAIDA:?Defina SAIDA como o diretório de saída}"

# Este repositório já contém o cliente web compilado.
test -f "$RAIZ/index.html"
test -f "$RAIZ/servers.json"
test -d "$RAIZ/assets"

mkdir -p "$SAIDA"
cp "$RAIZ/index.html" "$RAIZ/servers.json" "$SAIDA/"
cp -a "$RAIZ/assets" "$SAIDA/"

# Confirma que o HTML e os recursos necessários foram empacotados.
test -f "$SAIDA/assets/index-C0nTH1JV.js"
test -f "$SAIDA/assets/index-BLkIhPSX.css"
test -n "$(find "$SAIDA/assets" -maxdepth 1 -name '*.wasm' -print -quit)"

echo "Cliente web do Global-Strike preparado em: $SAIDA"
