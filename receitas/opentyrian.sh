. "$RAIZ/receitas/comum.sh"
baixar_fonte https://github.com/midzer/opentyrian emscripten
emmake make -k CC=emcc || true          # compila os .o (o link é feito abaixo, como no EMSCRIPTEN.md do projeto)
cd obj 2>/dev/null || cd src
mkdir -p data
curl -fsSL -o /tmp/tyrian21.zip https://camanis.net/tyrian/tyrian21.zip
unzip -o -j -q /tmp/tyrian21.zip -d data
emcc -flto -O3 -fno-rtti -fno-exceptions $(find . -name '*.o') -o index.html -sUSE_SDL=2 -sASYNCIFY -sASYNCIFY_IGNORE_INDIRECT -sENVIRONMENT=web \
  --preload-file data/ -sEXPORTED_RUNTIME_METHODS=['allocate'] -sASYNCIFY_ONLY=@"$(cd .. && pwd)/funcs.txt" -sSTACK_SIZE=131072 --closure 1
cp index.js index.wasm index.data "$SAIDA/"
moldurar index.js "OpenTyrian"
cp ../COPYING "$SAIDA/LICENCA.txt"
