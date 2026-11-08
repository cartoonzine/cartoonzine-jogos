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

# ---------------------------------------------------------------- dependências externas (só do manifesto confiável)
# dependencia_externa <id>: baixa o commit FIXO do modelo/dependencias-externas.json, compila para WebAssembly,
# confere que os cabeçalhos e as bibliotecas declarados existem e acrescenta em:
#   EXTERNAS_CFLAGS (-I…)   EXTERNAS_LIBS (caminhos .a)   EXTERNAS_CMAKE (array de -DVAR=valor)
# Id fora do manifesto = para com REVISAO (não baixa nem roda nada que não esteja declarado).
EXTERNAS_CFLAGS="${EXTERNAS_CFLAGS:-}"; EXTERNAS_LIBS="${EXTERNAS_LIBS:-}"; EXTERNAS_CMAKE=()
dependencia_externa() {
  local id="$1" man="$RAIZ/modelo/dependencias-externas.json" e
  e=$(jq -c --arg i "$id" '.externas[] | select(.id == $i)' "$man")
  [ -n "$e" ] || { echo "REVISAO: dependência externa '$id' não está no manifesto modelo/dependencias-externas.json"; exit 1; }
  local repo commit build dir
  repo=$(jq -r .repo <<<"$e"); commit=$(jq -r .commit <<<"$e"); build=$(jq -r .build <<<"$e")
  [[ "$commit" =~ ^[0-9a-f]{40}$ ]] || { echo "REVISAO: commit inválido no manifesto para $id"; exit 1; }
  [ "$build" = cmake ] || { echo "REVISAO: build '$build' de $id sem suporte"; exit 1; }
  dir="${DEPS:-/tmp/obra/deps}/$id"
  rm -rf "$dir" && mkdir -p "$dir" && (
    cd "$dir" && git init -q src && cd src && git remote add origin "$repo" &&
    git fetch -q --depth 1 origin "$commit" && git checkout -q FETCH_HEAD && [ "$(git rev-parse HEAD)" = "$commit" ]
  ) || { echo "REVISAO: não consegui baixar $id @ $commit"; exit 1; }
  mapfile -t ops < <(jq -r '.opcoes[]' <<<"$e")
  echo "== $id @ ${commit:0:12} ($(jq -r .licenca <<<"$e")) → cmake ${ops[*]}"
  emcmake cmake -S "$dir/src" -B "$dir/build" -DCMAKE_BUILD_TYPE=Release "${ops[@]}"
  cmake --build "$dir/build" -j"$(nproc)"
  local inc h lib libs=""
  inc="$dir/src/$(jq -r .include <<<"$e")"
  while read -r h; do [ -f "$inc/$h" ] || { echo "REVISAO: $id compilou mas não tem o cabeçalho $h em $inc"; exit 1; }; done < <(jq -r '.cabecalhos[]' <<<"$e")
  local libdir="$dir/build" pl; pl=$(jq -r '.pastaBibliotecas // empty' <<<"$e")
  if [ -n "$pl" ]; then [[ "$pl" =~ ^[A-Za-z0-9_./-]+$ && "$pl" != *..* ]] || { echo "REVISAO: pastaBibliotecas inválida em $id"; exit 1; }; libdir="$dir/src/$pl"; fi
  while read -r lib; do
    local achou=""; [ -d "$libdir" ] && achou=$(find "$libdir" -name "$lib" -type f | head -1)
    [ -n "$achou" ] && [ -s "$achou" ] || { echo "REVISAO: $id compilou mas não gerou $lib"; exit 1; }
    libs="$libs $achou"
  done < <(jq -r '.bibliotecas[]' <<<"$e")
  EXTERNAS_CFLAGS="$EXTERNAS_CFLAGS -I$inc"
  EXTERNAS_LIBS="$EXTERNAS_LIBS$libs"
  local k v
  while IFS=$'\t' read -r k v; do
    v="${v//\{include\}/$inc}"
    if [[ "$v" =~ \{lib:([^}]+)\} ]]; then v="${v//\{lib:${BASH_REMATCH[1]}\}/$(find "$libdir" -name "${BASH_REMATCH[1]}" -type f | head -1)}"; fi
    EXTERNAS_CMAKE+=("-D$k=$v")
  done < <(jq -r '.cmake | to_entries[] | [.key, .value] | @tsv' <<<"$e")
  echo "   include: $inc · libs:$libs"
  echo "dependência $id $commit ($repo)" >> "$SAIDA/FONTE.txt"
}
