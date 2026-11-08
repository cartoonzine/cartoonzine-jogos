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
