# Neverball tem o próprio build web oficial (emscripten/ball.mk); seguimos a mesma receita do projeto
. "$RAIZ/receitas/comum.sh"
baixar_fonte https://github.com/Neverball/neverball master
sudo apt-get update -q && sudo apt-get install -y -q libpng-dev libjpeg-dev pkg-config libsdl2-dev libcurl4-openssl-dev ffmpeg
make -j"$(nproc)" sols
./emscripten/install-gl4es.sh
make -j"$(nproc)" -f emscripten/ball.mk BUILD=release
cp -r js/. "$SAIDA/"
cp LICENSE.md "$SAIDA/LICENCA.txt"
