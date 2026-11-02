# Neverball tem o próprio build web oficial (emscripten/ball.mk); seguimos a mesma receita do projeto
. "$RAIZ/receitas/comum.sh"
baixar_fonte https://github.com/Neverball/neverball master
sudo apt-get update -q && sudo apt-get install -y -q libpng-dev libjpeg-dev pkg-config libsdl2-dev libcurl4-openssl-dev ffmpeg
make -j"$(nproc)" sols
./emscripten/install-gl4es.sh
make -j"$(nproc)" -f emscripten/ball.mk BUILD=release
cp -r js/. "$SAIDA/"
# Cartoonzine: abre direto no jogo (sem a tela "Play Now") e o jogo ocupa a tela toda do cartucho
python3 "$RAIZ/modelo/neverball-direto.py" "$SAIDA/index.html"
cp LICENSE.md "$SAIDA/LICENCA.txt"
