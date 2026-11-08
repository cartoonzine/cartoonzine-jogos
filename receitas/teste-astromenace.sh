. "$RAIZ/receitas/comum.sh"
# 🧩 RECEITA CANDIDATA (Prateleira da Studio, só regras) — cmake · FreeType, SDL2, OpenGL/WebGL, OpenAL, ALUT (freealut), SDL2_mixer
# Código: https://github.com/midzer/astromenace @ c9bd3886b4fc9c6eef04d5dcafd33bc541c97111. Só vira "pronta" depois que o workflow "Validar receita" passar.
# Os ajustes ficam na ficha do jogo (jogos.json → "ajustes"); edite lá ou aqui e valide de novo.
# ⚠️ REVISÃO NECESSÁRIA:
#   - Dependência sem port conhecido no Emscripten: ALUT (freealut) — não faz parte do OpenAL do Emscripten: a receita precisa compilar o freealut.
echo "REVISAO: Dependência sem port conhecido no Emscripten: ALUT (freealut) — não faz parte do OpenAL do Emscripten: a receita precisa compilar o freealut."
exit 1
