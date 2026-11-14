. "$RAIZ/receitas/comum.sh"
set -euo pipefail

# 🧩 RECEITA CANDIDATA — Brotato Web
# Código: https://github.com/degloved-net/brotato-web @ 124e458dbda8a117229fb8ac6962322c2e1e42e0
# Requer o projeto do jogo recuperado em work/project e Godot com templates Web.

fonte="${BROTATO_WEB_DIR:-$RAIZ/work/brotato-web-src}"
url="https://github.com/degloved-net/brotato-web"
commit="124e458dbda8a117229fb8ac6962322c2e1e42e0"

if [[ ! -d "$fonte/.git" ]]; then
    mkdir -p "$(dirname "$fonte")"
    git clone --no-checkout "$url" "$fonte"
fi

git -C "$fonte" fetch --quiet origin "$commit"
git -C "$fonte" checkout --quiet --detach "$commit"

if [[ ! -f "$fonte/work/project/project.godot" ]]; then
    echo "Projeto do jogo não encontrado em $fonte/work/project."
    echo "Recupere o projeto do jogo antes de adicionar mods e compilar."
    exit 1
fi

cd "$fonte"
sh scripts/add-mod.sh
sh scripts/build.sh
