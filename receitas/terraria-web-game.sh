# Na raiz do projeto
npm ci
npm run build

# O bundle estático fica em dist/
test -f dist/index.html || {
  echo "ERRO: o build não gerou dist/index.html."
  exit 1
}
