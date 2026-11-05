. "$RAIZ/receitas/comum.sh"

# 1. Baixar o código-fonte do port
baixar_fonte https://github.com/Carter54git/dethrace-ported-to-web main
FONTE=$(pwd)

# 2. Obter os dados da versão Demo/Shareware do Carmageddon (necessários para o .data)
# Baixa e descompacta a demo DOS de 1997 oficial no diretório esperado pelo build (Carma/)
mkdir -p Carma
curl -sL "https://archive.org/download/CarmageddonDemo/carmademo.zip" -o carmademo.zip || true
if [ -f carmademo.zip ]; then
    unzip -q -o carmademo.zip -d Carma/
fi

# 3. Configurar e Compilar via CMake + Emscripten
mkdir -p build && cd build

emcmake cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_WASM=ON \
    -DCARMAPATH="$FONTE/Carma"

emmake make -j$(nproc)

# 4. Copiar os artefatos gerados para a pasta de saída
# O CMake gera carmaweb.html (ou index.html), carmaweb.js, carmaweb.wasm e carmaweb.data
if [ -f carmaweb.html ]; then
    cp carmaweb.html "$SAIDA/index.html"
elif [ -f index.html ]; then
    cp index.html "$SAIDA/index.html"
fi

cp *.js *.wasm *.data "$SAIDA/" 2>/dev/null || true

# Se sua pipeline usa o helper de moldura/wrapper:
if command -v moldurar >/dev/null 2>&1 && [ -f "$SAIDA/carmaweb.js" ]; then
    moldurar carmaweb.js "Carmageddon"
elif command -v moldurar >/dev/null 2>&1 && [ -f "$SAIDA/index.js" ]; then
    moldurar index.js "Carmageddon"
fi

# 5. Licença do projeto
if [ -f "$FONTE/LICENSE" ]; then
    cp "$FONTE/LICENSE" "$SAIDA/LICENCA.txt"
elif [ -f "$FONTE/COPYING" ]; then
    cp "$FONTE/COPYING" "$SAIDA/LICENCA.txt"
fi
