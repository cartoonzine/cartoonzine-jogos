/**
 * Confere se a pasta de um jogo compilado está completa — não basta existir um index.html.
 *   node modelo/verificar-saida.mjs <pasta> [--dados pasta1,pasta2] [--github]
 * Regras: index.html carrega um .js que existe; o .js aponta para um .wasm que existe e é WebAssembly de verdade;
 * se o .js usa um pacote .data, ele existe e não está vazio; as pastas de dados declaradas estão dentro do pacote;
 * FONTE.txt registra o commit do código-fonte.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export function verificarSaida(pasta, { dados = [] } = {}) {
    const erros = [], info = {};
    const ler = n => fs.readFileSync(path.join(pasta, n));
    const existe = n => fs.existsSync(path.join(pasta, n)) && fs.statSync(path.join(pasta, n)).isFile();
    if (!existe('index.html')) return { ok: false, erros: ['Falta o index.html'], info };
    const html = ler('index.html').toString();
    const scripts = [...html.matchAll(/<script[^>]*\ssrc="([^"]+)"/g)].map(m => m[1]).filter(s => !/^(https?:)?\/\//.test(s));
    if (!scripts.length) erros.push('O index.html não carrega nenhum script do jogo');
    for (const s of scripts) if (!existe(s)) erros.push(`O index.html carrega ${s}, que não existe`);
    const js = scripts.filter(existe).map(s => ({ nome: s, txt: ler(s).toString() }));
    const principal = js.find(j => /\.wasm["']/.test(j.txt)) || js[0];
    if (principal) {
        info.js = principal.nome;
        const wasms = [...new Set([...principal.txt.matchAll(/["']([\w.-]+\.wasm)["']/g)].map(m => m[1]))];
        if (!wasms.length) erros.push(`${principal.nome} não aponta para nenhum .wasm`);
        for (const w of wasms) {
            if (!existe(w)) { erros.push(`Falta ${w} (usado por ${principal.nome})`); continue; }
            const b = ler(w);
            if (b.length < 8 || b[0] !== 0 || b[1] !== 0x61 || b[2] !== 0x73 || b[3] !== 0x6d) erros.push(`${w} não é um arquivo WebAssembly válido`);
            info.wasm = w; info.wasmBytes = b.length;
        }
        const todos = js.map(j => j.txt).join('\n');
        // o Emscripten escreve o nome do pacote como 'index.data' ou dentro de "datafile_index.data"
        const pacotes = [...new Set([...todos.matchAll(/["'](?:datafile_)?([\w.-]+\.data)["']/g)].map(m => m[1]))];
        for (const d of pacotes) {
            if (!existe(d)) erros.push(`Falta o pacote de dados ${d}`);
            else if (!fs.statSync(path.join(pasta, d)).size) erros.push(`O pacote de dados ${d} está vazio`);
            else info.dados = d;
        }
        for (const d of dados) {
            const alvo = '/' + String(d).replace(/^\/+|\/+$/g, '').split('@').pop().replace(/^\/+/, '');
            if (!pacotes.length) erros.push(`A receita declara a pasta de dados "${d}", mas o jogo não tem pacote .data`);
            else if (!new RegExp('filename["\']?\\s*:\\s*["\']' + alvo.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '/').test(todos)) erros.push(`A pasta de dados "${d}" não está dentro do pacote`);
        }
    }
    if (!existe('FONTE.txt') || !/[0-9a-f]{40}/.test(ler('FONTE.txt').toString())) erros.push('FONTE.txt não registra o commit do código-fonte');
    return { ok: !erros.length, erros, info };
}

if (process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1])) {
    const i = process.argv.indexOf('--dados');
    const dados = i > 0 ? process.argv[i + 1].split(',').filter(Boolean) : [];
    const r = verificarSaida(process.argv[2], { dados });
    const gh = process.argv.includes('--github');
    for (const e of r.erros) console.log(gh ? '::error title=Artefato com problema::' + e : '✗ ' + e);
    if (r.ok) console.log('✓ artefatos ok', JSON.stringify(r.info));
    process.exit(r.ok ? 0 : 1);
}
