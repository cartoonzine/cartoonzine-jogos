/**
 * Teste de inicialização num Chromium sem tela (Playwright): o jogo precisa carregar e começar a rodar sem erro.
 *   node modelo/testar-navegador.mjs <pasta do jogo> [--github]
 * Passa quando: o Emscripten chegou ao main() (Module.calledRun) e a tela de "Carregando" sumiu, sem erro de página,
 * sem "Aborted(" e sem arquivo do próprio jogo dando 404. Não joga o jogo: um jogo que trava depois de abrir passa aqui.
 */
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const TIPOS = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.data': 'application/octet-stream', '.txt': 'text/plain' };

export async function testarNavegador(pasta, { tempo = 30000, chromium } = {}) {
    if (!chromium) ({ chromium } = await import('playwright'));
    const raiz = path.resolve(pasta);
    const srv = http.createServer((req, res) => {
        const p = path.join(raiz, decodeURIComponent(new URL(req.url, 'http://x').pathname).replace(/\/$/, '/index.html'));
        if (!p.startsWith(raiz) || !fs.existsSync(p) || !fs.statSync(p).isFile()) { res.writeHead(404); return res.end(); }
        res.writeHead(200, { 'Content-Type': TIPOS[path.extname(p)] || 'application/octet-stream' }); fs.createReadStream(p).pipe(res);
    });
    await new Promise(r => srv.listen(0, '127.0.0.1', r));
    const url = `http://127.0.0.1:${srv.address().port}/index.html`;
    const erros = [];
    const nav = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader', '--autoplay-policy=no-user-gesture-required'] });
    try {
        const p = await nav.newPage({ viewport: { width: 960, height: 600 } });
        p.on('pageerror', e => erros.push('Erro na página: ' + String(e.message).slice(0, 300)));
        p.on('console', m => { if (/Aborted\(|exception thrown|RuntimeError/.test(m.text())) erros.push('Console: ' + m.text().slice(0, 300)); });
        p.on('response', r => { if (r.status() === 404 && r.url().startsWith(url.replace('index.html', ''))) erros.push('Arquivo não encontrado (404): ' + r.url().split('/').pop()); });
        await p.goto(url, { waitUntil: 'load' });
        const inicio = Date.now();
        let rodando = false;
        while (Date.now() - inicio < tempo && !erros.length) {
            rodando = await p.evaluate(() => !!(window.Module && window.Module.calledRun) && !document.getElementById('carregando')).catch(() => false);
            if (rodando) break;
            await p.waitForTimeout(500);
        }
        if (rodando) { await p.waitForTimeout(3000); }           // alguns jogos quebram logo depois de começar
        if (!rodando && !erros.length) erros.push(`O jogo não começou a rodar em ${tempo / 1000} s (o main() não foi chamado ou o carregamento travou)`);
        return { ok: !erros.length, erros };
    } finally { await nav.close(); srv.close(); }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1])) {
    const r = await testarNavegador(process.argv[2]);
    const gh = process.argv.includes('--github');
    for (const e of r.erros) console.log(gh ? '::error title=Teste no navegador::' + e : '✗ ' + e);
    if (r.ok) console.log('✓ o jogo abriu e começou a rodar no navegador');
    process.exit(r.ok ? 0 : 1);
}
