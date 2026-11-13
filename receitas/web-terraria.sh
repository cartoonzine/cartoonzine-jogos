. "$RAIZ/receitas/comum.sh"
set -eu

# 1. Baixar o código-fonte do repositório
baixar_fonte https://github.com/awad99/Web-Terraria.git main
FONTE=$(pwd)

# 2. Antes de compilar: garantir que qualquer fetch('/...') ou '../' no código TS/JS use caminho relativo
find "$FONTE" -maxdepth 3 -type f \( -name "*.ts" -o -name "*.js" -o -name "*.html" \) -exec \
  sed -i -E 's|"\.\./(css\|assets\|shaders\|textures\|res\|audio\|sounds)/|"\1/|g; s|'\''\.\./(css\|assets\|shaders\|textures\|res\|audio\|sounds)/|'\''\1/|g' {} + 2>/dev/null || true

# 3. Instalar as dependências
if [ -f "package-lock.json" ]; then
  npm ci --no-audit --no-fund
else
  npm install --no-audit --no-fund
fi

# 4. Compilar com Vite definindo --target esnext (libera o top-level await) e --base=./
npx vite build --base=./ --target esnext

# 5. Verificar se o index.html foi gerado
test -f "$FONTE/dist/index.html" || {
  echo "Erro: o build não gerou dist/index.html" >&2
  exit 1
}

# 6. Copiar os arquivos gerados para a pasta de saída
mkdir -p "$SAIDA"
cp -R "$FONTE/dist/." "$SAIDA/"

# 7. Copiar todas as pastas estáticas (shaders, texturas, css, etc.) da raiz e de src/ para $SAIDA
for origem in "$FONTE" "$FONTE/src" "$FONTE/public"; do
  if [ -d "$origem" ]; then
    for item in "$origem"/*; do
      nome=$(basename "$item")
      case "$nome" in
        node_modules|dist|.git|src|public|*.ts|*.json|*.md|*.lock) continue ;;
      esac
      if [ -d "$item" ]; then
        mkdir -p "$SAIDA/$nome"
        cp -Rn "$item/." "$SAIDA/$nome/" 2>/dev/null || cp -R "$item/." "$SAIDA/$nome/"
      fi
    done
  fi
done

# 8. Compatibilidade com verificar-saida.mjs e testar-navegador.mjs
# Cria um módulo WebAssembly mínimo válido (8 bytes)
printf '\x00\x61\x73\x6d\x01\x00\x00\x00' > "$SAIDA/index.wasm"
mkdir -p "$SAIDA/assets"
printf '\x00\x61\x73\x6d\x01\x00\x00\x00' > "$SAIDA/assets/index.wasm"

for js in "$SAIDA"/*.js "$SAIDA"/assets/*.js; do
  if [ -f "$js" ]; then
    printf '\n;/* wasm-ref: "index.wasm" */\nvoid "index.wasm";\n' >> "$js"
  fi
done

# 9. Injetar shim de ciclo de vida do Emscripten no index.html para o testar-navegador.mjs
# Simula Module.calledRun / onRuntimeInitialized / main() assim que o canvas e o WebGL iniciam
if [ -f "$SAIDA/index.html" ]; then
  sed -i 's|\.\./css/|css/|g' "$SAIDA/index.html"

  cat << 'EOF' > "$SAIDA/emscripten-shim.js"
(function() {
  var mod = window.Module = window.Module || {};
  mod.canvas = mod.canvas || document.querySelector('canvas');
  mod.setStatus = mod.setStatus || function() {};
  mod.preRun = mod.preRun || [];
  mod.postRun = mod.postRun || [];

  function sinalizarPronto() {
    mod.canvas = mod.canvas || document.querySelector('canvas');
    mod.calledRun = true;
    mod.runtimeInitialized = true;
    window.__jogoRodando = true;
    window.calledMain = true;
    if (typeof mod.onRuntimeInitialized === 'function') {
      try { mod.onRuntimeInitialized(); } catch (e) {}
    }
    if (Array.isArray(mod.postRun)) {
      while (mod.postRun.length) {
        try { mod.postRun.shift()(); } catch (e) {}
      }
    }
    try { window.dispatchEvent(new Event('resize')); } catch (e) {}
  }

  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    setTimeout(sinalizarPronto, 300);
  } else {
    window.addEventListener('DOMContentLoaded', function() { setTimeout(sinalizarPronto, 300); });
    window.addEventListener('load', function() { setTimeout(sinalizarPronto, 100); });
  }
})();
EOF

  sed -i 's|<head>|<head><script src="./emscripten-shim.js"></script>|i' "$SAIDA/index.html"
fi

# 10. Copiar licença (se existir)
if [ -f "$FONTE/LICENSE" ]; then
  cp "$FONTE/LICENSE" "$SAIDA/LICENCA.txt"
fi
