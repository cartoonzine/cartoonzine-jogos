. "$RAIZ/receitas/comum.sh"
# ⚙️ RECEITA AUTOMÁTICA (feita pela Prateleira da Studio) — tipo: desconhecido
# Se o robô falhar, ajuste aqui (dependências, opções do Emscripten, arquivos de dados) e tire o "rascunho" no jogos.json.
baixar_fonte https://github.com/woahhcrackers/GTA3Web.git main
FONTE=$(pwd)

# O repositório já contém o build Emscripten; não recompilar.
# Copie a árvore completa para o diretório de saída definido pela Prateleira.
mkdir -p "$DESTINO"
cp -a "$FONTE"/. "$DESTINO"/
