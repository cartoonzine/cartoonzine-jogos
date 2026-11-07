. "$RAIZ/receitas/comum.sh"
# O repositório já contém a versão web compilada; basta copiar os arquivos.
baixar_fonte https://github.com/woahhcrackers/GTA3Web.git main
FONTE=$(pwd)

# SAIDA é definida pelo workflow e representa a pasta de publicação.
cp -a "$FONTE"/. "$SAIDA"/
rm -rf "$SAIDA/.git"
