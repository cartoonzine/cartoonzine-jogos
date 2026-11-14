. "$RAIZ/receitas/comum.sh"
set -euo pipefail

# RAIZ é o repositório da prateleira. O cliente do jogo está no repositório
# Global-Strike e já vem compilado para a web.
baixar_commit \
  https://github.com/cartoonzine/Global-Strike.git \
  456b15f96e96e238b206262b96209aaf08568c93
FONTE=$(pwd)

for arquivo in index.html servers.json; do
  [[ -f "$FONTE/$arquivo" ]] || {
    echo "REVISAO: arquivo obrigatório não encontrado na fonte: $arquivo" >&2
    exit 1
  }
done
[[ -d "$FONTE/assets" ]] || {
  echo "REVISAO: diretório assets não encontrado na fonte" >&2
  exit 1
}

mkdir -p "$SAIDA"
cp "$FONTE/index.html" "$FONTE/servers.json" "$SAIDA/"
cp -a "$FONTE/assets" "$SAIDA/"

# O verificador procura os WASM na raiz da saída; o jogo continua com
# os arquivos originais em assets/ para os caminhos definidos pelo cliente.
find "$FONTE/assets" -maxdepth 1 -type f -name '*.wasm' -exec cp -t "$SAIDA" {} +

test -s "$SAIDA/FONTE.txt"
echo "Global-Strike web pronto em: $SAIDA"
