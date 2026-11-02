. "$RAIZ/receitas/comum.sh"
baixar_fonte https://github.com/midzer/jumpnbump emscripten
# 1) os dados do jogo (jumpbump.dat) são montados por ferramentas nativas do próprio projeto
make -C modify CC=gcc CFLAGS="-O2 -std=gnu89" LDFLAGS= 
make -C data
mkdir -p assets && cp data/jumpbump.dat assets/
# 2) o jogo em WebAssembly
sed -i 's/^\tranlib /\temranlib /' sdl/Makefile
sed -e "s#%%DATADIR%%#assets#g" < globals.pre > globals.h
emmake make index.html CC=emcc SDL_CFLAGS="-sUSE_SDL=2 -sUSE_SDL_MIXER=2" SDL_LIBS="-sUSE_SDL=2" EXE=
cp index.js index.wasm index.data "$SAIDA/"
moldurar index.js "Jump 'n Bump"
cp COPYING "$SAIDA/LICENCA.txt"
