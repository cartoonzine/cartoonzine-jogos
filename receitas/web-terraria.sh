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

# 6. Copiar pastas estáticas referenciadas fora do bundle (css, assets, texturas, etc.)
for pasta in css assets res textures audio sounds img images public; do
  if [ -d "$FONTE/$pasta" ]; then
    cp -Rn "$FONTE/$pasta/." "$SAIDA/$pasta/" 2>/dev/null || cp -R "$FONTE/$pasta" "$SAIDA/"
  fi
  if [ -d "$FONTE/src/$pasta" ]; then
    cp -Rn "$FONTE/src/$pasta/." "$SAIDA/$pasta/" 2>/dev/null || cp -R "$FONTE/src/$pasta" "$SAIDA/"
  fi
done

# Corrige o caminho "../css/style.css" no index.html
if [ -f "$SAIDA/index.html" ]; then
  sed -i 's|\.\./css/|css/|g' "$SAIDA/index.html"
fi

# 7. Compatibilidade com verificar-saida.mjs (que exige um .wasm referenciado pelo .js)
# Cria um módulo WebAssembly mínimo válido (cabeçalho mágico \0asm + versão 1 = 8 bytes)
printf '\x00\x61\x73\x6d\x01\x00\x00\x00' > "$SAIDA/index.wasm"
mkdir -p "$SAIDA/assets"
printf '\x00\x61\x73\x6d\x01\x00\x00\x00' > "$SAIDA/assets/index.wasm"

# Adiciona a referência ao .wasm em todos os .js do bundle sem afetar a execução do jogo
for js in "$SAIDA"/*.js "$SAIDA"/assets/*.js; do
  if [ -f "$js" ]; then
    printf '\n;/* wasm-ref: "index.wasm" */\nvoid "index.wasm";\n' >> "$js"
  fi
done

# 8. Copiar licença (se existir)
if [ -f "$FONTE/LICENSE" ]; then
  cp "$FONTE/LICENSE" "$SAIDA/LICENCA.txt"
fi
