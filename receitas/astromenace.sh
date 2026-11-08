. "$RAIZ/receitas/comum.sh"

# O port OpenAL do Emscripten não inclui ALUT; compile o FreeALUT para WebAssembly.
baixar_fonte https://github.com/midzer/astromenace.git emscripten

git clone -q --depth 1 https://github.com/vancegroup/freealut.git freealut

emcmake cmake -S freealut -B freealut/build \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_EXAMPLES=OFF \
  -DBUILD_TESTS=OFF \
  -DCMAKE_INSTALL_PREFIX="$PWD/freealut/install"

cmake --build freealut/build -j"$(nproc)"
cmake --install freealut/build

ALUT_PREFIX="$PWD/freealut/install"
ALUT_LIBRARY="$(find "$ALUT_PREFIX" -type f -name libalut.a -print -quit)"

test -f "$ALUT_PREFIX/include/AL/alut.h"
test -n "$ALUT_LIBRARY"

emcmake cmake -S . -B web \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="-sUSE_SDL=2" \
  -DCMAKE_CXX_FLAGS="-sUSE_SDL=2 -I$ALUT_PREFIX/include" \
  -DALUT_INCLUDE_DIR="$ALUT_PREFIX/include" \
  -DALUT_LIBRARY="$ALUT_LIBRARY" \
  -DCMAKE_EXE_LINKER_FLAGS="-sUSE_SDL=2 -sUSE_OPENAL=1 -sALLOW_MEMORY_GROWTH=1 -sASYNCIFY -Wl,--whole-archive $ALUT_LIBRARY -Wl,--no-whole-archive"

cmake --build web -j"$(nproc)"
publicar_saida web "Astromenace"
