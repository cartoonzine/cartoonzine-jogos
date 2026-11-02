. "$RAIZ/receitas/comum.sh"
# 1) jsoncpp em WebAssembly (o Freegemas usa para guardar as opções)
git clone -q --depth 1 -b 1.9.5 https://github.com/open-source-parsers/jsoncpp /tmp/jsoncpp
emcmake cmake -S /tmp/jsoncpp -B /tmp/jsoncpp/b -DCMAKE_BUILD_TYPE=Release -DJSONCPP_WITH_TESTS=OFF -DJSONCPP_WITH_POST_BUILD_UNITTEST=OFF \
  -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON -DBUILD_OBJECT_LIBS=OFF -DCMAKE_CXX_FLAGS="-O3 -fno-exceptions -DJSON_USE_EXCEPTION=0"
emmake make -C /tmp/jsoncpp/b jsoncpp_static
LIBJ=$(find /tmp/jsoncpp/b -name 'libjsoncpp*.a' | head -1)
# 2) o jogo (mesmas opções do EMSCRIPTEN.md do projeto)
baixar_fonte https://github.com/midzer/freegemas emscripten
em++ -std=c++11 -flto -O3 -fno-rtti -fno-exceptions -DJSON_USE_EXCEPTION=0 -Iinclude -I/tmp/jsoncpp/include src/*.cpp "$LIBJ" -o index.html \
  -sUSE_SDL=2 -sUSE_SDL_IMAGE=2 -sSDL2_IMAGE_FORMATS=png -sUSE_SDL_TTF=2 -sUSE_SDL_MIXER=2 -sSDL2_MIXER_FORMATS=ogg -sENVIRONMENT=web \
  -sALLOW_MEMORY_GROWTH=1 --preload-file media@media/
test "$(stat -c %s index.wasm)" -gt 100000   # garante que o jogo inteiro entrou
cp index.js index.wasm index.data "$SAIDA/"
moldurar index.js "Freegemas"
cp LICENSE "$SAIDA/LICENCA.txt"
