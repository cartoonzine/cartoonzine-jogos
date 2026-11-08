// node --test testes/
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { diagnosticar, anotacao, dependenciaDoCabecalho, TABELA } from '../modelo/diagnostico.mjs';
const log = n => fs.readFileSync(new URL('./logs/' + n, import.meta.url), 'utf8');

test('regressão AstroMenace: AL/alut.h ausente = dependência sem port (revisão), nunca sucesso', () => {
    const d = diagnosticar(log('astromenace-alut.txt'));
    assert.ok(d.length >= 1);
    assert.equal(d[0].tipo, 'dependencia-ausente');
    assert.equal(d[0].cabecalho, 'AL/alut.h');
    assert.equal(d[0].dependencia, 'alut');
    assert.match(d[0].mensagem, /sem port no Emscripten/);
    assert.equal(d.filter(p => p.cabecalho === 'AL/alut.h').length, 1);          // não repete
    assert.match(anotacao(d[0]), /^::error title=Dependência ausente::Falta o arquivo de cabeçalho AL\/alut\.h/);
});

test('cabeçalho com port conhecido sugere o port', () => {
    const d = diagnosticar(log('mazeofgalious-mixer.txt'));
    assert.deepEqual(d.map(p => p.dependencia), ['sdl2_mixer', 'sdl2_image']);
    assert.match(d[0].mensagem, /-sUSE_SDL_MIXER=2/);
});

test('erro de compilação comum, biblioteca e closure', () => {
    const d = diagnosticar(log('opengt4-abs.txt'));
    assert.equal(d[0].tipo, 'compilacao');
    assert.match(d[0].mensagem, /logger_view\.c:261: call to undeclared library function 'abs'/);
    const c = diagnosticar(log('mazeofgalious-closure.txt'));
    assert.deepEqual(c.map(p => p.tipo), ['dependencia-ausente', 'link']);
    assert.match(c[1].mensagem, /allocate/);
    assert.deepEqual(diagnosticar('tudo certo\n[100%] Built target jogo'), []);
});

test('tabela de dependências: as sem port ficam null (revisão)', () => {
    assert.equal(dependenciaDoCabecalho('AL/alut.h').port, null);
    assert.equal(dependenciaDoCabecalho('GL/glu.h').port, null);
    assert.deepEqual(dependenciaDoCabecalho('SDL_ttf.h').port, ['-sUSE_SDL_TTF=2']);
    assert.equal(dependenciaDoCabecalho('boost/asio.hpp').id, 'boost');
    assert.equal(dependenciaDoCabecalho('meu.h'), null);
    for (const d of TABELA) assert.ok(d.port === null || d.port.every(f => /^(-s[A-Z0-9_]+=\w+|-l\w+)$/.test(f)), d.id);
});

test('regressão AstroMenace (2º erro): gl4esinit.h ausente = dependência externa do manifesto, sem sucesso falso', () => {
    const d = diagnosticar(log('astromenace-gl4es.txt'));
    assert.equal(d[0].tipo, 'dependencia-ausente');
    assert.equal(d[0].externa, 'gl4es');
    assert.match(d[0].mensagem, /acrescente "gl4es" em ajustes\.externas/);
    assert.match(d[0].mensagem, /ptitSeb\/gl4es@c9895df/);
    const a = diagnosticar(log('astromenace-alut.txt'));
    assert.equal(a[0].externa, 'freealut');
    assert.match(a[0].mensagem, /acrescente "freealut"/);
});

test('header no lugar não basta: símbolo não resolvido no link é falha', () => {
    const d = diagnosticar(log('simbolo-indefinido.txt'));
    assert.deepEqual(d.map(p => p.tipo), ['simbolo', 'simbolo']);
    assert.match(d[0].mensagem, /gluPerspective/);
});

test('dependência fora da tabela e do manifesto = revisão; make sem regra; tudo explicado', () => {
    const d = diagnosticar(log('desconhecida.txt'));
    assert.equal(d[0].externa, null);
    assert.match(d[0].mensagem, /enet\/enet\.h \(dependência desconhecida: revisão necessária\)/);
    assert.match(diagnosticar(log('starfighter-make.txt'))[0].mensagem, /pr-starfighter\.mo/);
});

test('regressão AstroMenace (3º erro, build real com freealut + gl4es): símbolos mglu* no link apontam a GLU do manifesto', () => {
    const d = diagnosticar(log('astromenace-glu.txt'));
    assert.equal(d.length, 1);                                   // um aviso por biblioteca, não um por função
    assert.equal(d[0].tipo, 'simbolo');
    assert.equal(d[0].dependencia, 'glu');
    assert.equal(d[0].externa, 'glu');
    assert.match(d[0].mensagem, /mglu\w+ \(é da GLU: acrescente "glu" em ajustes\.externas\)/);
});

test('símbolo de biblioteca sem port e fora do manifesto = revisão', () => {
    const d = diagnosticar('wasm-ld: error: a.o: undefined symbol: alutInit\n', {});
    assert.equal(d[0].dependencia, 'alut');
    const sem = diagnosticar('wasm-ld: error: a.o: undefined symbol: enet_host_create\n');
    assert.match(sem[0].mensagem, /falta uma biblioteca ou um arquivo no build/);
});

test('regressão AstroMenace (4º erro, build real com freealut + gl4es + glu): funções do OpenGL antigo sem definição = revisão', () => {
    const d = diagnosticar(log('astromenace-gl-legado.txt'));
    assert.equal(d.length, 1);
    assert.equal(d[0].dependencia, 'opengl-legado');
    assert.match(d[0].mensagem, /revisão necessária/);
});
