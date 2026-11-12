. "$RAIZ/receitas/comum.sh"
set -eu

(
  cd "$RAIZ"
  npm ci
  npm run build
)

test -f "$RAIZ/dist/index.html" || {
  echo "Erro: o build não gerou dist/index.html" >&2
  exit 1
}

mkdir -p "$SAIDA"
cp -R "$RAIZ/dist/." "$SAIDA/"

printf '%s\n' \
  'https://github.com/cartoonzine/Web-Terraria @ 716854657810089f3d977bd36c7a28e8a7a0201f' \
  > "$SAIDA/FONTE.txt"
