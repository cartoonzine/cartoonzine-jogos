# Após clonar o repositório em "$fonte" e entrar nele:
cd "$fonte"

if [[ ! -f work/project/project.godot ]]; then
    if [[ -z "${BROTATO_GAME_FILES:-}" || ! -e "$BROTATO_GAME_FILES" ]]; then
        echo "Configure BROTATO_GAME_FILES com a pasta do projeto do jogo ou o caminho para o .pck."
        exit 1
    fi
    bash scripts/recover.sh "$BROTATO_GAME_FILES"
fi

# Opcional: só adiciona um mod quando um ZIP for fornecido.
if [[ -n "${BROTATO_MOD_ZIP:-}" ]]; then
    bash scripts/add-mod.sh "$BROTATO_MOD_ZIP"
fi

bash scripts/build.sh

mkdir -p "$SAIDA"
cp -a build/web/. "$SAIDA/"
cp build/web.html "$SAIDA/"
