. "$RAIZ/receitas/comum.sh"
# Abuse (fork web do midzer) — segue o EMSCRIPTEN.md do fork. Sem os timbres MIDI (dgguspat), que não estão no repositório: só efeitos em WAV.
baixar_fonte https://github.com/midzer/abuse.git emscripten
FONTE=$(pwd)
export EMCC_CFLAGS="-sUSE_SDL=2 -sUSE_SDL_MIXER=2 -sSDL2_MIXER_FORMATS=[wav]"
mkdir -p build && cd build
emcmake cmake ..
emmake make -k -j"$(nproc)" || true
unset EMCC_CFLAGS
cd "$(dirname "$(find . -path '*CMakeFiles/abuse.dir/*' -name 'game.cpp.o' | head -1)")"
em++ -flto -O3 -fno-rtti -fno-exceptions *.o $(ls */*.o 2>/dev/null) "$FONTE/build/src/imlib/libimlib.a" "$FONTE/build/src/lisp/liblisp.a" "$FONTE/build/src/net/libnet.a" "$FONTE/build/src/sdlport/libsdlport.a" \
  -o index.html -sUSE_SDL=2 -sUSE_SDL_MIXER=2 -sSDL2_MIXER_FORMATS=[wav] -sASYNCIFY -sENVIRONMENT=web --preload-file "$FONTE/data@data/" \
  -sSTACK_SIZE=131072 -sALLOW_MEMORY_GROWTH=1 --closure 1 "-sEXPORTED_RUNTIME_METHODS=['allocate','ALLOC_NORMAL']"
cp index.js index.wasm index.data "$SAIDA/"
moldurar index.js "Abuse"
cp "$FONTE/COPYING" "$SAIDA/LICENCA.txt"
