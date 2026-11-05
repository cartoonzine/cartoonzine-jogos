. "$RAIZ/receitas/comum.sh"
# Maze of Galious (fork web do midzer) — receita feita a partir do EMSCRIPTEN.md do próprio fork
baixar_fonte https://github.com/midzer/mazeofgalious.git emscripten
# os "ports" do Emscripten (SDL_image/SDL_mixer) precisam estar ligados já na compilação, senão faltam os .h
export EMCC_CFLAGS="-sUSE_SDL=2 -sUSE_SDL_IMAGE=2 -sSDL2_IMAGE_FORMATS=[pcx] -sUSE_SDL_MIXER=2 -sSDL2_MIXER_FORMATS=[ogg]"
emmake make -k -j"$(nproc)" || true
unset EMCC_CFLAGS
em++ -flto -O3 -fno-rtti -fno-exceptions sources/*.o -o index.html \
  -sUSE_SDL=2 -sUSE_SDL_IMAGE=2 -sSDL2_IMAGE_FORMATS=[pcx] -sUSE_SDL_MIXER=2 -sSDL2_MIXER_FORMATS=[ogg] \
  -sASYNCIFY -sENVIRONMENT=web -sINITIAL_MEMORY=256mb \
  --preload-file graphics/ --preload-file rooms/ --preload-file sound/ --closure 1 "-sEXPORTED_RUNTIME_METHODS=['allocate','ALLOC_NORMAL']"
cp index.js index.wasm index.data "$SAIDA/"
moldurar index.js "Maze of Galious"
cp LICENSE "$SAIDA/LICENCA.txt"
