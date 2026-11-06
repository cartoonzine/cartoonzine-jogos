. "$RAIZ/receitas/comum.sh"
# Powermanga (fork web do midzer) — segue o EMSCRIPTEN.md do fork (ASYNCIFY completo: a lista funcs.txt é de um Emscripten antigo)
baixar_fonte https://github.com/midzer/powermanga.git emscripten
FONTE=$(pwd)
export EMCC_CFLAGS="-sUSE_SDL=2 -sUSE_SDL_MIXER=2 -sSDL2_MIXER_FORMATS=[ogg]"
mkdir -p build && cd build
emcmake cmake ..
emmake make -k -j"$(nproc)" || true
unset EMCC_CFLAGS
cd "$(dirname "$(find . -path '*CMakeFiles/powermanga.dir/*' -name 'main.c.o' | head -1)")"
emcc -flto -O3 -fno-rtti -fno-exceptions *.o -o index.html -sUSE_SDL=2 -sUSE_SDL_MIXER=2 -sSDL2_MIXER_FORMATS=[ogg] -sASYNCIFY -sENVIRONMENT=web \
  --preload-file "$FONTE/data@data/" --preload-file "$FONTE/graphics@graphics/" --preload-file "$FONTE/sounds@sounds/" --preload-file "$FONTE/texts@texts/" \
  -sINITIAL_MEMORY=128mb --closure 1 "-sEXPORTED_RUNTIME_METHODS=['allocate','ALLOC_NORMAL']"
cp index.js index.wasm index.data "$SAIDA/"
moldurar index.js "Powermanga"
cp "$FONTE/COPYING" "$SAIDA/LICENCA.txt"
