. "$RAIZ/receitas/comum.sh"
set -eu

# 1. Baixar o código-fonte do repositório (ou do seu fork cartoonzine/Web-Terraria)
baixar_fonte https://github.com/awad99/Web-Terraria.git main
FONTE=$(pwd)

# 2. Instalar dependências (usa npm ci se houver lockfile, senão npm install)
if [ -f "package-lock.json" ]; then
  npm ci --no-audit --no-fund
else
  npm install --no-audit --no-fund
fi

# 3. Compilar com Vite forçando caminhos relativos (--base=./) para funcionar em subpastas
npx vite build --base=./ || npm run build -- --base=./

# 4. Verificar se o index.html foi gerado
test -f "$FONTE/dist/index.html" || {
  echo "Erro: o build não gerou dist/index.html" >&2
  exit 1
}

# 5. Copiar os arquivos gerados para a pasta de saída
mkdir -p "$SAIDA"
cp -R "$FONTE/dist/." "$SAIDA/"

# 6. Copiar licença (se existir)
if [ -f "$FONTE/LICENSE" ]; then
  cp "$FONTE/LICENSE" "$SAIDA/LICENCA.txt"
fi
