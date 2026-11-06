. "$RAIZ/receitas/comum.sh"

# 1. Baixar o repositório do port
baixar_fonte https://github.com/Lolendor/reVCDOS.git main
FONTE=$(pwd)

# O reVCDOS é um cliente estático na pasta 'dist/'. Não precisa de Emscripten!
# Ele busca os assets via proxy ou arquivos locais (vcbr/ e vcsky/).
# Como queremos servir os arquivos estáticos e sem servidor Python, 
# precisamos do pacote (.bin) com todos os assets do jogo já empacotados.

# 2. Baixar o arquivo de assets empacotados do DOS.Zone
echo "Baixando o arquivo de assets (revcdos.bin) com ~300MB+..."
curl -sL "https://folder.morgen.qzz.io/revcdos.bin" -o revcdos.bin

# 3. Desempacotar os assets usando o utilitário Python incluso no repositório
# O script downloader_brotli.py extrai o .bin em uma pasta 'unpacked/<hash>/'
echo "Extraindo assets (isso pode demorar e usar bastante RAM)..."
python3 server.py --unpacked revcdos.bin --port 8000 &
SERVER_PID=$!

# Aguarda um pouco para o Python descompactar os diretórios vcbr e vcsky
sleep 15
kill $SERVER_PID || true

# Procura a pasta descompactada dentro de 'unpacked/'
HASH_DIR=$(ls -1 unpacked/ 2>/dev/null | head -n 1)

if [ -z "$HASH_DIR" ]; then
    echo "Erro: Falha ao extrair os assets. Diretório unpacked/ vazio."
    exit 1
fi

# 4. Preparar o diretório de saída ($SAIDA)
# Copia o frontend web estático
cp -r dist/* "$SAIDA/"

# Copia as pastas de assets extraídas para dentro de $SAIDA
cp -r unpacked/$HASH_DIR/vcbr "$SAIDA/vcbr"
cp -r unpacked/$HASH_DIR/vcsky "$SAIDA/vcsky"

# 5. Adaptar o frontend para modo 100% estático (Static Hosting)
# O game.js (ou fetch.js) normalmente faz chamadas para a porta 8000 (Proxy Python).
# Precisamos apontar as requisições para as pastas locais /vcbr/ e /vcsky/
# Como o projeto foi desenhado primariamente para um servidor proxy, a adaptação mais simples
# é usar variáveis globais que o loader JS aceita ou modificar as URLs de fetch.
cd "$SAIDA"

# Substitui URLs padrão que apontariam para o proxy/backend pelas pastas estáticas relativas
if [ -f "game.js" ]; then
    sed -i 's|http://localhost:8000/vcbr/|vcbr/|g' game.js
    sed -i 's|http://localhost:8000/vcsky/|vcsky/|g' game.js
    sed -i 's|/vcbr/|vcbr/|g' game.js
    sed -i 's|/vcsky/|vcsky/|g' game.js
fi

if [ -f "modules/fetch.js" ]; then
    sed -i 's|http://localhost:8000/vcbr/|vcbr/|g' modules/fetch.js
    sed -i 's|http://localhost:8000/vcsky/|vcsky/|g' modules/fetch.js
fi

# 6. Finalização e limpeza
if command -v moldurar >/dev/null 2>&1; then
    moldurar index.js "GTA Vice City (reVCDOS)"
fi

if [ -f "$FONTE/LICENSE" ]; then
    cp "$FONTE/LICENSE" "$SAIDA/LICENCA.txt"
fi

echo "Receita concluída com sucesso. O frontend e os assets estáticos estão em $SAIDA."
