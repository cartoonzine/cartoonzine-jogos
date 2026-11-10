. "$RAIZ/receitas/comum.sh"

# Web-Terraria: aplicação web TypeScript compilada pelo Vite.
# Requer Node.js 18+ e um navegador moderno com WebGL ou WebGPU.

npm ci
npm run build

# Servir a versão compilada para abrir no navegador.
npm run preview -- --host 0.0.0.0 --port 4173 --strictPort
