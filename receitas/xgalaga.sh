. "$RAIZ/receitas/comum.sh"
baixar_fonte https://github.com/midzer/xgalaga-sdl emscripten
FONTE=$(pwd)
autoreconf -i
emconfigure ./configure --enable-sdl2 CFLAGS="-flto -O3 -fno-rtti -fno-exceptions"
emmake make -k || true
cd src
# ASYNCIFY completo: a lista de funções do projeto (funcs.txt) foi feita para um Emscripten mais antigo e travava o jogo
emcc -flto -O3 -fno-rtti -fno-exceptions *.o -o index.html -sUSE_SDL=2 -sUSE_SDL_TTF=2 -sUSE_SDL_GFX=2 -sUSE_SDL_IMAGE=2 -sUSE_SDL_MIXER=2 -sSDL2_IMAGE_FORMATS=png -sSDL2_MIXER_FORMATS=wav \
  -sASYNCIFY -sENVIRONMENT=web \
  --preload-file "$FONTE/fonts/@fonts/" --preload-file "$FONTE/images/@images/" --preload-file "$FONTE/levels/@levels/" --preload-file "$FONTE/sounds/@sounds/" \
  --closure 1 -sEXPORTED_RUNTIME_METHODS=['allocate']
cp index.js index.wasm index.data "$SAIDA/"
moldurar index.js "XGalaga"
cp "$FONTE/COPYING" "$SAIDA/LICENCA.txt"
