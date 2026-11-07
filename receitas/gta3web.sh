. "$RAIZ/receitas/comum.sh"
# ⚙️ RECEITA AUTOMÁTICA (feita pela Prateleira da Studio) — tipo: web-estatico
# Este repositório já vem com o build do jogo para Web:
# index.html, re3.js, re3.wasm, re3.data.*, audio/, models/, txd/, etc.
# Portanto não há compilação via Emscripten neste passo; apenas publicamos o conteúdo.

baixar_fonte https://github.com/woahhcrackers/GTA3Web.git main
FONTE=$(pwd)

# Publica o jogo pronto em um diretório estático.
mkdir -p "$DESTINO"
cp -a "$FONTE"/. "$DESTINO"/

# Ajusta permissões mínimas para servir via HTTP
chmod -R a+rX "$DESTINO"
