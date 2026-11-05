. "$RAIZ/receitas/comum.sh"
# ⚙️ RECEITA AUTOMÁTICA (feita pela Prateleira da Studio) — tipo: make · sdl2 · já tem versão web
# Se o robô falhar, ajuste aqui (dependências, opções do Emscripten, arquivos de dados) e tire o "rascunho" no jogos.json.
baixar_fonte https://github.com/midzer/mazeofgalious.git emscripten
emmake make -j"$(nproc)" CC=emcc CXX=em++ LDFLAGS="-sALLOW_MEMORY_GROWTH=1 -sASYNCIFY -sUSE_SDL=2"
publicar_saida . "Mazeofgalious"
