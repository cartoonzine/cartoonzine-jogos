. "$RAIZ/receitas/comum.sh"

baixar_fonte https://github.com/midzer/astromenace.git emscripten

# AstroMenace usa ALUT para carregar WAV; o port OpenAL não fornece essa biblioteca.
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

# O branch Emscripten do AstroMenace inclui gl4esinit.h e chama initialize_gl4es().
GL4ES_COMMIT="${GL4ES_COMMIT:-c9895df34cd466c23bc60c2bd3db3d87e98fcbe7}"
GL4ES_SRC="$PWD/gl4es-src"

git init -q "$GL4ES_SRC"
git -C "$GL4ES_SRC" remote add origin https://github.com/ptitSeb/gl4es.git
git -C "$GL4ES_SRC" fetch -q --depth 1 origin "$GL4ES_COMMIT"
git -C "$GL4ES_SRC" checkout -q --detach FETCH_HEAD

test -f "$GL4ES_SRC/include/gl4esinit.h"

emcmake cmake -S "$GL4ES_SRC" -B "$GL4ES_SRC/build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DNOX11=ON \
  -DNOEGL=ON \
  -DSTATICLIB=ON
cmake --build "$GL4ES_SRC/build" -j"$(nproc)"

GL4ES_LIBRARY="$(find "$GL4ES_SRC" -type f -name libGL.a -print -quit)"
test -n "$GL4ES_LIBRARY"

emcmake cmake -S . -B web \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="-sUSE_SDL=2" \
  -DCMAKE_CXX_FLAGS="-sUSE_SDL=2 -I$ALUT_PREFIX/include -I$GL4ES_SRC/include" \
  -DALUT_INCLUDE_DIR="$ALUT_PREFIX/include" \
  -DALUT_LIBRARY="$ALUT_LIBRARY" \
  -DOPENGL_gl_LIBRARY:FILEPATH="$GL4ES_LIBRARY" \
  -DCMAKE_EXE_LINKER_FLAGS="-sUSE_SDL=2 -sUSE_OPENAL=1 -sFULL_ES2=1 -sALLOW_MEMORY_GROWTH=1 -sASYNCIFY"

cmake --build web -j"$(nproc)"
publicar_saida web "Astromenace"
