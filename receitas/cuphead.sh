. "$RAIZ/receitas/comum.sh"

baixar_fonte https://github.com/web-ports/cuphead.git main
FONTE=$(pwd)

# Este repositório já contém o build Unity WebGL; não há compilação Emscripten.
cp -a "$FONTE/index.html" "$FONTE/Build" "$FONTE/TemplateData" "$SAIDA/"

# O index original aponta para uma revisão do jogo no jsDelivr.
# Remova esse <base> para carregar os arquivos da cópia publicada junto ao index.
if grep -q '<base href="https://cdn.jsdelivr.net/gh/web-ports/cuphead@' "$SAIDA/index.html"; then
  sed -i '/<base href="https:\/\/cdn.jsdelivr.net\/gh\/web-ports\/cuphead@/d' "$SAIDA/index.html"
else
  echo "Não encontrei a tag <base> esperada em index.html"
  exit 1
fi
