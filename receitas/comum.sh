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
# usado pelas receitas automáticas da Prateleira (Studio): acha o jogo compilado (.wasm + .js) numa pasta e publica
publicar_saida() { # publicar_saida <pasta do build> <título>
  local pasta="$1" titulo="$2" wasm base js
  wasm=$(find "$pasta" -maxdepth 3 -name '*.wasm' -printf '%s %p\n' | sort -nr | head -1 | cut -d' ' -f2-)
  [ -n "$wasm" ] || { echo "não achei nenhum .wasm em $pasta"; exit 1; }
  base="${wasm%.wasm}"; js="$base.js"; [ -f "$js" ] || js="$base"
  [ -f "$js" ] || { echo "não achei o .js de $wasm"; exit 1; }
  local nome; nome=$(basename "$base")
  cp "$js" "$SAIDA/$nome.js"; cp "$wasm" "$SAIDA/$nome.wasm"
  for x in data worker.js; do [ -f "$base.$x" ] && cp "$base.$x" "$SAIDA/$nome.$x"; done
  moldurar "$nome.js" "$titulo"
  local lic; lic=$(ls -1 COPYING* LICENSE* LICENCE* 2>/dev/null | head -1 || true)
  [ -n "$lic" ] && cp "$lic" "$SAIDA/LICENCA.txt" || true
}
