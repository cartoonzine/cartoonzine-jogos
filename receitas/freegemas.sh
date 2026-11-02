. "$RAIZ/receitas/comum.sh"
baixar_fonte https://github.com/midzer/freegemas emscripten
FONTE=$(pwd)
mkdir -p build && cd build
emcmake cmake .. -DCMAKE_BUILD_TYPE=Release
emmake make -k || true                  # compila; o link é o do EMSCRIPTEN.md do projeto
OBJS=$(find . -name '*.o' -path '*freegemas*' | tr '\n' ' ')
LIBJ=$(find . -name 'libjsoncpp*.a' | head -1)
em++ -flto -O3 -fno-rtti -fno-exceptions $OBJS $LIBJ -o index.html -sUSE_SDL=2 -sUSE_SDL_IMAGE=2 -sSDL2_IMAGE_FORMATS=png -sUSE_SDL_TTF=2 -sUSE_SDL_MIXER=2 \
  -sSDL2_MIXER_FORMATS=ogg -sENVIRONMENT=web --preload-file "$FONTE/media@media/" --closure 1
cp index.js index.wasm index.data "$SAIDA/"
moldurar index.js "Freegemas"
cp "$FONTE/LICENSE" "$SAIDA/LICENCA.txt"
