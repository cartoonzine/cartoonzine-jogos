. "$RAIZ/receitas/comum.sh"
# Bombermaaan (fork web do midzer) — o "guia" dele é um comentário no trunk/src/CMakeLists.txt. SDL 1.2.
# O jogo procura os arquivos em data/images, data/sounds e data/levels.
# Sem -sSTB_IMAGE: as imagens são decodificadas pelo próprio navegador no carregamento (com STB faltavam funções e a tela ficava preta).
baixar_fonte https://github.com/midzer/Bombermaaan.git emscripten
FONTE=$(pwd)
export EMCC_CFLAGS="-sUSE_SDL=1 -sUSE_SDL_MIXER=1"
emcmake cmake -S trunk -B build -DCMAKE_BUILD_TYPE=Release -DGRAPHICS_LIBRARY_OPTION=SDL
cmake --build build -j"$(nproc)" -- -k || true
unset EMCC_CFLAGS
OBJ=$(dirname "$(find build -path '*CMakeFiles/Bombermaaan.dir/*' -name 'WinMain.cpp.o' | head -1)")
TINY=$(find build -name 'libtinyxml.a' | head -1)
emcc -O3 $(find "$OBJ" -name '*.o' | sort) "$TINY" -o index.html -sUSE_SDL=1 -sUSE_SDL_IMAGE=1 -sUSE_SDL_MIXER=1 -sASYNCIFY -sENVIRONMENT=web \
  -sINITIAL_MEMORY=128mb -sSTACK_SIZE=524288 -sERROR_ON_UNDEFINED_SYMBOLS=0 \
  --preload-file "$FONTE/trunk/res/images@/data/images" --preload-file "$FONTE/trunk/res/sounds@/data/sounds" --preload-file "$FONTE/trunk/levels@/data/levels"
cp index.js index.wasm index.data "$SAIDA/"
moldurar index.js "Bombermaaan"
cp "$FONTE/LICENSE.txt" "$SAIDA/LICENCA.txt"
