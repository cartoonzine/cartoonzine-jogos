. "$RAIZ/receitas/comum.sh"

set -eu

REPO="https://github.com/degloved-net/brotato-web.git"
REV="0803b3f2803341be20998a4621a1141220d6102a"
SRC="$RAIZ/fontes/brotato-web"

if [ -z "${BROTATO_GAME_DIR:-}" ]; then
    echo "Defina BROTATO_GAME_DIR para a pasta do projeto Godot ou para o arquivo .pck da sua cópia do Brotato."
    exit 1
fi

if [ ! -e "$BROTATO_GAME_DIR" ]; then
    echo "Arquivos do jogo não encontrados: $BROTATO_GAME_DIR"
    exit 1
fi

for cmd in git rsync patch sed realpath; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Dependência ausente: $cmd"
        exit 1
    fi
done

mkdir -p "$(dirname "$SRC")"
if [ ! -d "$SRC/.git" ]; then
    git clone "$REPO" "$SRC"
fi
git -C "$SRC" checkout --detach "$REV"

bash "$SRC/scripts/recover.sh" "$BROTATO_GAME_DIR"
bash "$SRC/scripts/build.sh"

echo "Exports web gerados em $SRC/build/"
