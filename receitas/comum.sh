# Funções comuns das receitas. Cada receita roda dentro do contêiner do Emscripten com:
#   $SAIDA  = pasta onde o jogo pronto tem de ficar (index.html + arquivos)
#   $RAIZ   = raiz deste repositório
set -euo pipefail
baixar_fonte() {   # baixar_fonte <repo git> <branch>
  rm -rf fonte && git clone -q --depth 1 -b "$2" "$1" fonte
  cd fonte
  echo "commit $(git rev-parse HEAD) de $1 ($2)" > "$SAIDA/FONTE.txt"
}
# troca a página padrão do Emscripten pela moldura do Cartoonzine (tela cheia, sem console nem logo)
moldurar() {       # moldurar <arquivo .js principal> <título>
  local js="$1" titulo="$2"
  sed -e "s#{{JS}}#${js}#g" -e "s#{{TITULO}}#${titulo}#g" "$RAIZ/modelo/moldura.html" > "$SAIDA/index.html"
}
