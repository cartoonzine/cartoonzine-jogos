. "$RAIZ/receitas/comum.sh"
# 🧩 RECEITA CANDIDATA (Prateleira da Studio, só regras) — cmake · FreeType, SDL2, OpenGL/WebGL, OpenAL, ALUT (freealut), libogg, libvorbis
# Código: https://github.com/viewizard/astromenace @ bbdb3ac5af2774c92b85c4d9b2a238f606911e66. Só vira "pronta" depois que o workflow "Validar receita" passar.
# Os ajustes ficam na ficha do jogo (jogos.json → "ajustes"); edite lá ou aqui e valide de novo.
baixar_commit https://github.com/viewizard/astromenace.git bbdb3ac5af2774c92b85c4d9b2a238f606911e66
FONTE=$(pwd)
dependencia_externa freealut   # manifesto: modelo/dependencias-externas.json (commit fixo)
preparar_ports_cmake freetype sdl2 opengl openal ogg vorbis OGG_LIBRARY=lib:ogg OGG_INCLUDE_DIR=inc:ogg VORBIS_LIBRARY=lib:vorbis VORBISFILE_LIBRARY=lib:vorbisfile VORBISFILE_INCLUDE_DIR=inc:vorbis
emcmake cmake -S "." -B build-web -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="-sUSE_FREETYPE=1 -sUSE_SDL=2 -sUSE_OGG=1 -sUSE_VORBIS=1 $EXTERNAS_CFLAGS" -DCMAKE_CXX_FLAGS="-sUSE_FREETYPE=1 -sUSE_SDL=2 -sUSE_OGG=1 -sUSE_VORBIS=1 $EXTERNAS_CFLAGS" \
  -DCMAKE_EXE_LINKER_FLAGS="-sUSE_FREETYPE=1 -sUSE_SDL=2 -lGL -lopenal -sUSE_OGG=1 -sUSE_VORBIS=1 -sALLOW_MEMORY_GROWTH=1 -sENVIRONMENT=web -sFORCE_FILESYSTEM=1 $EXTERNAS_LIBS" "${EXTERNAS_CMAKE[@]}" "${PORTS_CMAKE[@]}"
cmake --build build-web -j"$(nproc)"
PASTA_BUILD=build-web
publicar_jogo "$PASTA_BUILD" "astromenace" "Teste AstroMenace original" "gamedata@/gamedata"
for l in COPYING COPYING.txt LICENSE LICENSE.txt LICENSE.md LICENCE; do if [ -f "$FONTE/$l" ]; then cp "$FONTE/$l" "$SAIDA/LICENCA.txt"; break; fi; done
