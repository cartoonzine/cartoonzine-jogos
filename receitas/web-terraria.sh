. "$RAIZ/receitas/comum.sh"

repo="https://github.com/cartoonzine/Web-Terraria.git"
commit="716854657810089f3d977bd36c7a28e8a7a0201f"
src="/tmp/obra/Web-Terraria"

git clone --quiet "$repo" "$src"
git -C "$src" checkout --quiet "$commit"

cd "$src"
npm ci
npm run build
cp -a dist/. "$SAIDA/"
