. "$RAIZ/receitas/comum.sh"
# 🧩 RECEITA CANDIDATA (Prateleira da Studio, só regras) — cmake
# Código: https://github.com/gta-reversed/gta-reversed @ 49638dfd82ad82971e3d9621cb07b6b9d133e402. Só vira "pronta" depois que o workflow "Validar receita" passar.
# Os ajustes ficam na ficha do jogo (jogos.json → "ajustes"); edite lá ou aqui e valide de novo.
baixar_commit https://github.com/gta-reversed/gta-reversed.git 49638dfd82ad82971e3d9621cb07b6b9d133e402
FONTE=$(pwd)
emcmake cmake -S "." -B build-web -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="" -DCMAKE_CXX_FLAGS="" \
  -DCMAKE_EXE_LINKER_FLAGS="-sALLOW_MEMORY_GROWTH=1 -sENVIRONMENT=web"
cmake --build build-web -j"$(nproc)"
PASTA_BUILD=build-web
publicar_jogo "$PASTA_BUILD" "" "Gta Reversed"
for l in COPYING COPYING.txt LICENSE LICENSE.txt LICENSE.md LICENCE; do if [ -f "$FONTE/$l" ]; then cp "$FONTE/$l" "$SAIDA/LICENCA.txt"; break; fi; done
