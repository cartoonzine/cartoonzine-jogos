. "$RAIZ/receitas/comum.sh"
# 🧩 RECEITA CANDIDATA (Prateleira da Studio, só regras) — make · SDL2, SDL2_image, SDL2_mixer
# Código: https://github.com/midzer/vectoroids @ f88a3aa5005edcaa700f36c988bd245d5bf2b032. Só vira "pronta" depois que o workflow "Validar receita" passar.
# Os ajustes ficam na ficha do jogo (jogos.json → "ajustes"); edite lá ou aqui e valide de novo.
baixar_commit https://github.com/midzer/vectoroids.git f88a3aa5005edcaa700f36c988bd245d5bf2b032
FONTE=$(pwd)
# make: as opções do Emscripten entram pelo EMCC_CFLAGS, que o emcc/em++ usa ao compilar E ao linkar
export EMCC_CFLAGS="-sUSE_SDL=2 -sUSE_SDL_IMAGE=2 -sUSE_SDL_MIXER=2 -sALLOW_MEMORY_GROWTH=1 -sENVIRONMENT=web -sFORCE_FILESYSTEM=1 -sSDL2_IMAGE_FORMATS=[jpg] -sSDL2_MIXER_FORMATS=[mod,wav] -sASYNCIFY"
emmake make -C "." -j"$(nproc)" CC=emcc CXX=em++
unset EMCC_CFLAGS
PASTA_BUILD="."
publicar_jogo "$PASTA_BUILD" "" "Vectoroids" "data@/data"
for l in COPYING COPYING.txt LICENSE LICENSE.txt LICENSE.md LICENCE; do if [ -f "$FONTE/$l" ]; then cp "$FONTE/$l" "$SAIDA/LICENCA.txt"; break; fi; done
