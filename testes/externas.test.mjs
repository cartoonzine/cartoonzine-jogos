// dependencia_externa (receitas/comum.sh) sem rede e sem Emscripten: repositório git local + emcmake/cmake de mentira
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const RAIZ = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const MAN = JSON.parse(fs.readFileSync(path.join(RAIZ, 'modelo/dependencias-externas.json'), 'utf8')).externas;

test('manifesto: cada dependência tem repo, commit fixo de 40 letras, licença, opções, cabeçalhos e bibliotecas', () => {
    for (const e of MAN) {
        assert.match(e.id, /^[a-z0-9-]+$/);
        assert.match(e.repo, /^https:\/\/github\.com\/[\w.-]+\/[\w.-]+\.git$/);
        assert.match(e.commit, /^[0-9a-f]{40}$/, e.id);
        assert.ok(e.licenca && ['cmake', 'autotools'].includes(e.build) && e.cabecalhos.length && e.bibliotecas.length, e.id);
        for (const o of e.opcoes) assert.match(o, e.build === 'cmake' ? /^-D[A-Z0-9_]+=[A-Za-z0-9_.-]+$/ : /^--[a-z0-9-]+(=[A-Za-z0-9_.-]+)?$/);
        for (const [k, v] of Object.entries(e.ambiente || {})) { assert.match(k, /^[A-Z_][A-Z0-9_]*$/); assert.ok(!/[`$;|&<>]/.test(v), v); }
        for (const r of e.requer || []) assert.ok(MAN.findIndex(x => x.id === r) >= 0 && MAN.findIndex(x => x.id === r) < MAN.indexOf(e), `${e.id} requer ${r}`);
    }
    assert.deepEqual(MAN.map(e => e.id).sort(), ['freealut', 'gl4es', 'glu']);
});

function ambiente() {
    const t = fs.mkdtempSync(path.join(os.tmpdir(), 'czx-'));
    // "repositório" da dependência
    const repo = path.join(t, 'alutfake');
    fs.mkdirSync(path.join(repo, 'include/AL'), { recursive: true });
    fs.writeFileSync(path.join(repo, 'include/AL/alut.h'), '/* ok */');
    const g = (...a) => execFileSync('git', ['-C', repo, ...a], { stdio: 'pipe' }).toString().trim();
    execFileSync('git', ['init', '-q', repo]); g('-c', 'user.email=a@b', '-c', 'user.name=t', 'add', '.'); g('-c', 'user.email=a@b', '-c', 'user.name=t', 'commit', '-qm', 'x');
    g('config', 'uploadpack.allowReachableSHA1InWant', 'true');
    const sha = g('rev-parse', 'HEAD');
    // cópia do repositório da prateleira com um manifesto apontando para o repo local
    const raiz = path.join(t, 'raiz');
    fs.mkdirSync(path.join(raiz, 'receitas'), { recursive: true }); fs.mkdirSync(path.join(raiz, 'modelo'));
    fs.copyFileSync(path.join(RAIZ, 'receitas/comum.sh'), path.join(raiz, 'receitas/comum.sh'));
    const ext = { ...MAN.find(e => e.id === 'freealut'), repo: 'file://' + repo, commit: sha };
    fs.writeFileSync(path.join(raiz, 'modelo/dependencias-externas.json'), JSON.stringify({ externas: [ext] }));
    // emcmake / cmake de mentira: o "build" gera a biblioteca declarada
    const bin = path.join(t, 'bin'); fs.mkdirSync(bin);
    fs.writeFileSync(path.join(bin, 'emcmake'), '#!/bin/bash\nexec "$@"\n', { mode: 0o755 });
    fs.writeFileSync(path.join(bin, 'cmake'), '#!/bin/bash\necho "cmake $*" >> "$LOG_CMAKE"\nif [ "$1" = --build ]; then mkdir -p "$2/src"; echo lib > "$2/src/libalut.a"; fi\n', { mode: 0o755 });
    const saida = path.join(t, 'saida'); fs.mkdirSync(saida);
    return { t, raiz, bin, saida, sha };
}
const roda = (amb, cmd) => execFileSync('bash', ['-c', `. "$RAIZ/receitas/comum.sh"; cd '${amb.t}'; ${cmd}`], {
    env: { ...process.env, RAIZ: amb.raiz, SAIDA: amb.saida, DEPS: path.join(amb.t, 'deps'), LOG_CMAKE: path.join(amb.t, 'cmake.log'), PATH: amb.bin + ':' + process.env.PATH }, stdio: 'pipe' }).toString();

test('dependência conhecida e fixada: compila no commit certo e entrega include, biblioteca e variáveis do CMake', () => {
    const a = ambiente();
    const out = roda(a, 'dependencia_externa freealut; echo "CF=$EXTERNAS_CFLAGS"; echo "LIBS=$EXTERNAS_LIBS"; printf "CM=%s\\n" "${EXTERNAS_CMAKE[@]}"');
    const inc = path.join(a.t, 'deps/freealut/src/include'), lib = path.join(a.t, 'deps/freealut/build/src/libalut.a');
    assert.match(out, new RegExp('CF= -I' + inc + '\\n'));
    assert.match(out, new RegExp('LIBS= ' + lib + '\\n'));
    assert.match(out, new RegExp('CM=-DALUT_INCLUDE_DIR=' + inc + '\\n'));
    assert.match(out, new RegExp('CM=-DALUT_LIBRARY=' + lib + '\\n'));
    assert.match(fs.readFileSync(path.join(a.t, 'cmake.log'), 'utf8'), /-DBUILD_SHARED_LIBS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TESTS=OFF/);
    assert.match(fs.readFileSync(path.join(a.saida, 'FONTE.txt'), 'utf8'), new RegExp('dependência freealut ' + a.sha));
});

test('dependência fora do manifesto = REVISAO, sem baixar nem rodar nada', () => {
    const a = ambiente();
    assert.throws(() => roda(a, 'dependencia_externa enet'), e => /REVISAO: dependência externa 'enet' não está no manifesto/.test(e.stdout.toString()));
    assert.ok(!fs.existsSync(path.join(a.t, 'cmake.log')));
    assert.ok(!fs.existsSync(path.join(a.t, 'deps')));
});

test('compilou mas não gerou a biblioteca declarada = REVISAO (header sozinho não resolve)', () => {
    const a = ambiente();
    fs.writeFileSync(path.join(a.bin, 'cmake'), '#!/bin/bash\nexit 0\n', { mode: 0o755 });
    assert.throws(() => roda(a, 'dependencia_externa freealut'), e => /REVISAO: freealut compilou mas não gerou libalut\.a/.test(e.stdout.toString()));
});

test('externa que requer outra: sem a outra antes = REVISAO, sem compilar nada', () => {
    const a = ambiente();
    const man = JSON.parse(fs.readFileSync(path.join(a.raiz, 'modelo/dependencias-externas.json'), 'utf8'));
    man.externas.push({ ...man.externas[0], id: 'glu', requer: ['gl4es'], build: 'autotools', opcoes: ['--disable-shared'] });
    fs.writeFileSync(path.join(a.raiz, 'modelo/dependencias-externas.json'), JSON.stringify(man));
    assert.throws(() => roda(a, 'dependencia_externa glu'), e => /REVISAO: glu precisa de 'gl4es' antes/.test(e.stdout.toString()));
    assert.ok(!fs.existsSync(path.join(a.t, 'deps')));
});

test('preparar_ports_cmake: compila o port, confere o caminho e passa -DVAR; caminho que não existe = REVISAO', () => {
    const a = ambiente();
    fs.copyFileSync(path.join(RAIZ, 'modelo/ports-cmake.json'), path.join(a.raiz, 'modelo/ports-cmake.json'));
    const cache = path.join(a.t, 'cache');
    fs.writeFileSync(path.join(a.bin, 'em-config'), `#!/bin/bash\necho ${cache}\n`, { mode: 0o755 });
    fs.writeFileSync(path.join(a.bin, 'embuilder'), `#!/bin/bash\nmkdir -p ${cache}/sysroot/include/SDL2 ${cache}/sysroot/lib/wasm32-emscripten && touch ${cache}/sysroot/lib/wasm32-emscripten/libSDL2.a\n`, { mode: 0o755 });
    const out = roda(a, 'preparar_ports_cmake sdl2 naoexiste SDL_LIB_DO_JOGO=lib:SDL2 SDL_INC=inc:sdl2; printf "P=%s\\n" "${PORTS_CMAKE[@]}"');
    assert.match(out, new RegExp('P=-DSDL_LIB_DO_JOGO=' + cache + '/sysroot/lib/wasm32-emscripten/libSDL2\\.a\\n'));
    assert.match(out, new RegExp('P=-DSDL_INC=' + cache + '/sysroot/include/SDL2\\n'));
    assert.throws(() => roda(a, 'preparar_ports_cmake X=lib:naoexiste'), e => /REVISAO: X pede lib:naoexiste/.test(e.stdout.toString()));
    assert.throws(() => roda(a, 'preparar_ports_cmake "A;B=lib:SDL2"'), e => /REVISAO: variável inválida/.test(e.stdout.toString()));
    assert.match(out, new RegExp('P=-DSDL2_INCLUDE_DIR=' + cache + '/sysroot/include/SDL2\\n'));
    assert.match(out, new RegExp('P=-DSDL2_LIBRARY=' + cache + '/sysroot/lib/wasm32-emscripten/libSDL2\\.a\\n'));
    fs.writeFileSync(path.join(a.bin, 'embuilder'), '#!/bin/bash\nexit 0\n', { mode: 0o755 });
    fs.rmSync(cache, { recursive: true, force: true });
    assert.throws(() => roda(a, 'preparar_ports_cmake sdl2'), e => /REVISAO: port sdl2 compilado, mas não achei/.test(e.stdout.toString()));
});
