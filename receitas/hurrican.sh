. "$RAIZ/receitas/comum.sh"
# Hurrican (fork web do midzer) — segue o EMSCRIPTEN.md do fork (ASYNCIFY completo: a lista funcs.txt é de um Emscripten antigo)
baixar_fonte https://github.com/midzer/hurrican.git emscripten
FONTE=$(pwd)
export EMCC_CFLAGS="-sUSE_SDL=2 -sUSE_SDL_IMAGE=2 -sSDL2_IMAGE_FORMATS=[png] -sUSE_SDL_MIXER=2 -sSDL2_MIXER_FORMATS=[mod,wav]"
mkdir -p Hurrican/build && cd Hurrican/build
emcmake cmake -DCMAKE_BUILD_TYPE=Release -DRENDERER=GLES2 -DFBO=OFF -DOPENMPT=OFF -DFAST_RANDOM=ON -DFAST_TRIG=ON -DDISABLE_EXCEPTIONS=ON -DUSE_PRECOMPILED_HEADERS=OFF ..
emmake make -k -j"$(nproc)" || true
unset EMCC_CFLAGS
cd "$(dirname "$(find . -path '*CMakeFiles/hurrican.dir/*' -name 'Main.cpp.o' -o -path '*CMakeFiles/hurrican.dir/*' -name 'main.cpp.o' | head -1)")"
em++ -flto -O3 -fno-exceptions -fno-rtti */*.o *.o -o index.html -sFULL_ES2=1 -lGL -sUSE_SDL=2 -sUSE_SDL_IMAGE=2 -sSDL2_IMAGE_FORMATS=[png] -sUSE_SDL_MIXER=2 -sSDL2_MIXER_FORMATS=[mod,wav] \
  -sASYNCIFY -sENVIRONMENT=web --preload-file "$FONTE/Hurrican/data@data/" --preload-file "$FONTE/Hurrican/lang@lang/" \
  --closure 1 -Wl,-u,fileno -sINITIAL_HEAP=64mb -sALLOW_MEMORY_GROWTH=1 "-sEXPORTED_RUNTIME_METHODS=['allocate','ALLOC_NORMAL']"
cp index.js index.wasm index.data "$SAIDA/"
moldurar index.js "Hurrican"
sed -n '/1.2 Enduser license agreement/,/1.3 System/p' "$FONTE/Hurrican/readme.txt" > "$SAIDA/LICENCA.txt"
