. "$RAIZ/receitas/comum.sh"
# ⚙️ RECEITA AUTOMÁTICA (feita pela Prateleira da Studio) — tipo: cmake · sdl2 · já tem versão web
# Se o robô falhar, ajuste aqui (dependências, opções do Emscripten, arquivos de dados) e tire o "rascunho" no jogos.json.
baixar_fonte https://github.com/midzer/astromenace.git emscripten
emcmake cmake -S . -B web -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-sUSE_SDL=2" -DCMAKE_CXX_FLAGS="-sUSE_SDL=2" -DCMAKE_EXE_LINKER_FLAGS="-sALLOW_MEMORY_GROWTH=1 -sASYNCIFY -sUSE_SDL=2"
cmake --build web -j"$(nproc)"
publicar_saida web "Astromenace"
