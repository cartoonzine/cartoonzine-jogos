. "$RAIZ/receitas/comum.sh"
# ⚙️ RECEITA AUTOMÁTICA (feita pela Prateleira da Studio) — tipo: cmake · sdl2
# Se o robô falhar, ajuste aqui (dependências, opções do Emscripten, arquivos de dados) e tire o "rascunho" no jogos.json.
baixar_fonte https://github.com/MrGoodGuy2144/OpenGT4.git main
FONTE=$(pwd)
export EMCC_CFLAGS="-sUSE_SDL=2 -sUSE_SDL_IMAGE=2 -sSDL2_IMAGE_FORMATS=[png,jpg,bmp,pcx] -sUSE_SDL_MIXER=2 -sSDL2_MIXER_FORMATS=[ogg,wav,mod,mp3]"
emcmake cmake -S . -B web -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXE_LINKER_FLAGS="-sALLOW_MEMORY_GROWTH=1 -sASYNCIFY -sENVIRONMENT=web"
cmake --build web -j"$(nproc)"
publicar_saida web "Grand Turismo 4"
