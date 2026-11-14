. "$RAIZ/receitas/comum.sh"

# 🧩 RECEITA CANDIDATA — Brotato Web
# Código: https://github.com/degloved-net/brotato-web @ 124e458dbda8a117229fb8ac6962322c2e1e42e0
# Requer os arquivos do jogo fornecidos pelo usuário, Godot 3.6.x ou 4.3+,
# templates de exportação Web e as ferramentas indicadas pelo projeto.
set -euo pipefail

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
    echo "Aponte para os arquivos locais do jogo quando solicitado."
    bash "$fonte/scripts/recover.sh"
fi

bash "$fonte/scripts/build.sh"

echo "Build concluído: $fonte/build/web.html"
echo "Sirva esse arquivo por um servidor HTTP local para jogar no navegador."
