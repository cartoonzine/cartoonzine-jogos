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
moldurar() {       # moldurar <arquivo .js principal> <título> [script que carrega antes, ex.: dados.js]
  local js="$1" titulo="$2" antes=""
  [ -n "${3:-}" ] && antes="<script src=\"$3\"></script>"
  sed -e "s#{{JS}}#${js}#g" -e "s#{{TITULO}}#${titulo}#g" -e "s#{{ANTES}}#${antes}#g" "$RAIZ/modelo/moldura.html" > "$SAIDA/index.html"
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

# ---------------------------------------------------------------- receitas da Prateleira (Studio)
# baixa EXATAMENTE o commit analisado (não o "último" do branch): o build fica reproduzível
baixar_commit() {  # baixar_commit <repo git> <sha de 40 letras> [submodulos]
  [[ "$2" =~ ^[0-9a-f]{40}$ ]] || { echo "REVISAO: commit inválido: $2"; exit 1; }
  rm -rf fonte && mkdir fonte && cd fonte
  git init -q && git remote add origin "$1"
  git fetch -q --depth 1 origin "$2"
  git checkout -q FETCH_HEAD
  [ "$(git rev-parse HEAD)" = "$2" ] || { echo "REVISAO: o commit baixado não é o $2"; exit 1; }
  if [ "${3:-}" = submodulos ]; then git submodule update --init --recursive --depth 1 -q; fi
  echo "commit $2 de $1" > "$SAIDA/FONTE.txt"
}
# empacota pastas de dados num dados.data + dados.js (o index.html carrega antes do jogo). Cada item: origem[@destino]
empacotar_dados() {
  local fp args=() d origem destino
  fp="$(dirname "$(readlink -f "$(command -v emcc)")")/tools/file_packager.py"
  for d in "$@"; do
    origem="${d%%@*}"; destino="/${origem}"; [[ "$d" == *@* ]] && destino="${d#*@}"
    [ -d "$origem" ] || [ -f "$origem" ] || { echo "REVISAO: a pasta de dados '$origem' não existe no código-fonte"; exit 1; }
    args+=(--preload "$(readlink -f "$origem")@$destino")
  done
  (cd "$SAIDA" && python3 "$fp" dados.data "${args[@]}" --js-output=dados.js)
}
# publica o jogo compilado: <pasta do build> <alvo ou ""> <título> [pastas de dados...]
# Sem "chutar": se não achar o .wasm do alvo (ou achar mais de um sem alvo definido), para com REVISAO.
publicar_jogo() {
  local pasta="$1" alvo="$2" titulo="$3"; shift 3
  local wasm n
  if [ -n "$alvo" ]; then
    wasm=$(find "$pasta" -name "$alvo.wasm" -not -path '*/CMakeFiles/*' | head -1)
  else
    n=$(find "$pasta" -name '*.wasm' -not -path '*/CMakeFiles/*' | wc -l)
    [ "$n" = 1 ] || { echo "REVISAO: achei $n arquivos .wasm em $pasta; defina o ajuste 'alvo' (nome do executável do jogo)"; exit 1; }
    wasm=$(find "$pasta" -name '*.wasm' -not -path '*/CMakeFiles/*')
  fi
  [ -n "$wasm" ] || { echo "REVISAO: não achei o .wasm do jogo em $pasta"; exit 1; }
  local base="${wasm%.wasm}" js nome
  js="$base.js"; [ -f "$js" ] || js="$base"
  [ -f "$js" ] || { echo "REVISAO: não achei o .js de $wasm"; exit 1; }
  nome=$(basename "$base")
  cp "$js" "$SAIDA/$nome.js"; cp "$wasm" "$SAIDA/$nome.wasm"
  if [ -f "$base.data" ]; then cp "$base.data" "$SAIDA/$nome.data"; fi
  if [ $# -gt 0 ]; then empacotar_dados "$@"; moldurar "$nome.js" "$titulo" dados.js; else moldurar "$nome.js" "$titulo"; fi
}
