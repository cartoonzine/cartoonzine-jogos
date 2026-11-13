. "$RAIZ/receitas/comum.sh"
set -eu

# 1. Baixar o código-fonte do repositório
baixar_fonte https://github.com/awad99/Web-Terraria.git main
FONTE=$(pwd)

# 2. Instalar as dependências
if [ -f "package-lock.json" ]; then
  npm ci --no-audit --no-fund
else
  npm install --no-audit --no-fund
fi

# 3. Compilar com Vite definindo --target esnext (libera o top-level await) e --base=./
npx vite build --base=./ --target esnext

# 4. Verificar se o index.html foi gerado
test -f "$FONTE/dist/index.html" || {
  echo "Erro: o build não gerou dist/index.html" >&2
  exit 1
}

# 5. Copiar os arquivos gerados para a pasta de saída
mkdir -p "$SAIDA"
cp -R "$FONTE/dist/." "$SAIDA/"

# 6. Garantir que pastas estáticas referenciadas fora do bundle (como css/ ou assets/) também vão para $SAIDA
for pasta in css assets res textures audio sounds img images; do
  if [ -d "$FONTE/$pasta" ] && [ ! -d "$SAIDA/$pasta" ]; then
    cp -R "$FONTE/$pasta" "$SAIDA/$pasta"
  fi
  if [ -d "$FONTE/src/$pasta" ] && [ ! -d "$SAIDA/$pasta" ]; then
    cp -R "$FONTE/src/$pasta" "$SAIDA/$pasta"
  fi
done

# Corrige o caminho "../css/style.css" no index.html caso o original aponte para uma pasta acima
if [ -f "$SAIDA/index.html" ]; then
  sed -i 's|\.\./css/|css/|g' "$SAIDA/index.html"
fi

# 7. Copiar licença (se existir)
if [ -f "$FONTE/LICENSE" ]; then
  cp "$FONTE/LICENSE" "$SAIDA/LICENCA.txt"
fi
