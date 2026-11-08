import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { verificarSaida } from '../modelo/verificar-saida.mjs';

const RAIZ = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
function jogo({ wasm = true, wasmBom = true, data = true, html = true, fonte = true } = {}) {
    const d = fs.mkdtempSync(path.join(os.tmpdir(), 'czj-'));
    if (html) fs.writeFileSync(path.join(d, 'index.html'), '<canvas></canvas><script async src="jogo.js"></script>');
    fs.writeFileSync(path.join(d, 'jogo.js'), 'var a="jogo.wasm";p.addRunDependency("datafile_jogo.data");x([{filename:"/graphics/a.png",start:0,end:3}])');
    if (wasm) fs.writeFileSync(path.join(d, 'jogo.wasm'), wasmBom ? Buffer.from([0, 0x61, 0x73, 0x6d, 1, 0, 0, 0]) : Buffer.from('<html>404</html>'));
    if (data) fs.writeFileSync(path.join(d, 'jogo.data'), 'abc');
    if (fonte) fs.writeFileSync(path.join(d, 'FONTE.txt'), 'commit ' + 'a'.repeat(40) + ' de https://x (main)');
    return d;
}

test('saída completa passa; index.html sozinho não basta', () => {
    assert.deepEqual(verificarSaida(jogo(), { dados: ['graphics'] }).erros, []);
    const so = fs.mkdtempSync(path.join(os.tmpdir(), 'czj-'));
    fs.writeFileSync(path.join(so, 'index.html'), '<p>oi</p>');
    assert.equal(verificarSaida(so).ok, false);
});

test('falta wasm, wasm falso, falta .data, pasta de dados fora do pacote, sem commit', () => {
    assert.match(verificarSaida(jogo({ wasm: false })).erros.join(), /Falta jogo\.wasm/);
    assert.match(verificarSaida(jogo({ wasmBom: false })).erros.join(), /não é um arquivo WebAssembly/);
    assert.match(verificarSaida(jogo({ data: false })).erros.join(), /Falta o pacote de dados jogo\.data/);
    assert.match(verificarSaida(jogo(), { dados: ['sounds'] }).erros.join(), /"sounds" não está dentro do pacote/);
    assert.match(verificarSaida(jogo({ fonte: false })).erros.join(), /FONTE\.txt/);
});

test('receita com erro falha de verdade (set -euo pipefail do comum.sh, sem || true escondendo)', () => {
    const d = fs.mkdtempSync(path.join(os.tmpdir(), 'czj-'));
    const rec = path.join(d, 'r.sh');
    fs.writeFileSync(rec, '. "$RAIZ/receitas/comum.sh"\nfalse\necho "não devia chegar aqui"\n');
    assert.throws(() => execFileSync('bash', ['-c', `. '${rec}'`], { env: { ...process.env, RAIZ, SAIDA: d }, stdio: 'pipe' }));
    fs.writeFileSync(rec, '. "$RAIZ/receitas/comum.sh"\necho ok | grep -q nada | cat\n');
    assert.throws(() => execFileSync('bash', ['-c', `. '${rec}'`], { env: { ...process.env, RAIZ, SAIDA: d }, stdio: 'pipe' }));
});

test('publicar_jogo não chuta: 2 .wasm sem alvo = REVISAO; com alvo publica o certo; baixar_commit recusa commit inválido', () => {
    const d = fs.mkdtempSync(path.join(os.tmpdir(), 'czj-'));
    const b = path.join(d, 'build'), s = path.join(d, 'saida');
    fs.mkdirSync(b); fs.mkdirSync(s);
    for (const n of ['jogo', 'ferramenta']) { fs.writeFileSync(path.join(b, n + '.js'), 'x'); fs.writeFileSync(path.join(b, n + '.wasm'), 'x'); }
    const roda = cmd => execFileSync('bash', ['-c', `. "$RAIZ/receitas/comum.sh"; cd '${d}'; ${cmd}`], { env: { ...process.env, RAIZ, SAIDA: s }, stdio: 'pipe' }).toString();
    assert.throws(() => roda('publicar_jogo build "" "Jogo"'), e => /REVISAO: achei 2 arquivos \.wasm/.test(e.stdout.toString()));
    roda('publicar_jogo build jogo "Jogo"');
    assert.ok(fs.existsSync(path.join(s, 'jogo.wasm')) && !fs.existsSync(path.join(s, 'ferramenta.wasm')));
    assert.match(fs.readFileSync(path.join(s, 'index.html'), 'utf8'), /<script async src="jogo\.js">/);
    assert.throws(() => roda('baixar_commit https://example.invalid/x.git main'), e => /REVISAO: commit inválido/.test(e.stdout.toString()));
});
