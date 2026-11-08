. "$RAIZ/receitas/comum.sh"
# 🧩 RECEITA CANDIDATA (Prateleira da Studio, só regras) — autotools · SDL2, SDL2_image, SDL2_mixer
# Código: https://github.com/midzer/starfighter @ 211fa3e5c3a2e6b50f17cccc937ee9004a165869. Só vira "pronta" depois que o workflow "Validar receita" passar.
# Os ajustes ficam na ficha do jogo (jogos.json → "ajustes"); edite lá ou aqui e valide de novo.
baixar_commit https://github.com/midzer/starfighter.git 211fa3e5c3a2e6b50f17cccc937ee9004a165869
FONTE=$(pwd)
cd "."
[ -x configure ] || autoreconf -fi
CFLAGS="-sUSE_SDL=2 -sUSE_SDL_IMAGE=2 -sUSE_SDL_MIXER=2" CXXFLAGS="-sUSE_SDL=2 -sUSE_SDL_IMAGE=2 -sUSE_SDL_MIXER=2" LDFLAGS="-sUSE_SDL=2 -sUSE_SDL_IMAGE=2 -sUSE_SDL_MIXER=2 -sALLOW_MEMORY_GROWTH=1 -sENVIRONMENT=web -sFORCE_FILESYSTEM=1 -sSDL2_IMAGE_FORMATS=[png,jpg] -sSDL2_MIXER_FORMATS=[ogg,mod] -sASYNCIFY" emconfigure ./configure --host=wasm32-unknown-emscripten
emmake make -j"$(nproc)"
cd "$FONTE"
PASTA_BUILD="."
publicar_jogo "$PASTA_BUILD" "" "Starfighter" "data@/data" "gfx@/gfx" "music@/music" "sound@/sound"
for l in COPYING COPYING.txt LICENSE LICENSE.txt LICENSE.md LICENCE; do if [ -f "$FONTE/$l" ]; then cp "$FONTE/$l" "$SAIDA/LICENCA.txt"; break; fi; done
