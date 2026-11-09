. "$RAIZ/receitas/comum.sh"

APP_DIR="$RAIZ/jogos/stardew-wasm"
PORT=8765

if [ ! -f "$APP_DIR/index.html" ] || [ ! -f "$APP_DIR/game.js" ] || [ ! -d "$APP_DIR/_framework" ]; then
	echo "ERRO: instalação incompleta de stardew-wasm em $APP_DIR"
	exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
	echo "ERRO: stardew-wasm precisa de python3 para servir os arquivos localmente."
	exit 1
fi

python3 -m http.server "$PORT" \
	--bind 127.0.0.1 \
	--directory "$APP_DIR" &
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null || true' EXIT

URL="http://127.0.0.1:$PORT/"
sleep 1

if command -v xdg-open >/dev/null 2>&1; then
	xdg-open "$URL" || true
else
	echo "Abra no navegador: $URL"
fi

wait "$SERVER_PID"
