/**
 * Diagnóstico de um log de compilação (só regras, sem IA): acha os erros de verdade e explica em português.
 *   node modelo/diagnostico.mjs <log> [--github]   → imprime o resumo; com --github vira anotações "::error" do Actions
 * Usado por .github/workflows/validar.yml. Testes: node --test testes/
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const AQUI = path.dirname(fileURLToPath(import.meta.url));
export const TABELA = JSON.parse(fs.readFileSync(path.join(AQUI, 'dependencias.json'), 'utf8')).dependencias;

/** cabeçalho → dependência conhecida (ou null) */
export function dependenciaDoCabecalho(h, tabela = TABELA) {
    return tabela.find(d => d.cabecalhos.some(c => c.endsWith('/') ? h.startsWith(c) : h === c)) || null;
}

const REGRAS = [
    { tipo: 'cabecalho', re: /^(.+?):(\d+):\d+: fatal error: '([^']+)' file not found/ },
    { tipo: 'biblioteca', re: /wasm-ld: error: unable to find library -l(\S+)/ },
    { tipo: 'simbolo', re: /(?:wasm-ld: )?error: undefined symbol: (\S+)/ },
    { tipo: 'cmake', re: /Could NOT find (\S+?)\b.*\(missing: ([^)]+)\)/, soSeFatal: true },
    { tipo: 'cmake', re: /CMake Error.*?: (.+)$/ },
    { tipo: 'cmake', re: /Could not find a package configuration file provided by "([^"]+)"/ },
    { tipo: 'configure', re: /^configure: error: (.+)$/ },
    { tipo: 'closure', re: /JSC_UNDEFINED_VARIABLE\] variable (\S+) is undeclared/ },
    { tipo: 'git', re: /^fatal: (.+)$/ },
    { tipo: 'receita', re: /^(receita ainda não feita|não achei nenhum \.wasm.*|não achei o \.js.*|REVISAO: .+)$/ },
    { tipo: 'compilador', re: /^(.+?):(\d+):\d+: error: (.+)$/ }
];

/** Lê o log e devolve os problemas (no máximo `max`, sem repetir). */
export function diagnosticar(log, { max = 6 } = {}) {
    const linhas = String(log || '').split(/\r?\n/).map(l => l.replace(/^\S*Z /, '').replace(/\x1b\[[0-9;]*m/g, ''));
    const achados = [], vistos = new Set();
    for (const l of linhas) {
        for (const r of REGRAS) {
            const m = r.re.exec(l);
            if (!m) continue;
            if (r.soSeFatal) continue;            // "Could NOT find" sozinho é só aviso do CMake (o build pode seguir)
            let p;
            if (r.tipo === 'cabecalho') {
                const dep = dependenciaDoCabecalho(m[3]);
                p = { tipo: 'dependencia-ausente', arquivo: m[1], linha: +m[2], cabecalho: m[3], dependencia: dep ? dep.id : null,
                    mensagem: `Falta o arquivo de cabeçalho ${m[3]}` + (dep ? ` (${dep.nome}: ` + (dep.port ? `ligue o port ${dep.port.join(' ')})` : `sem port no Emscripten — ${dep.nota})`) : ' (dependência desconhecida: revisão necessária)') };
            } else if (r.tipo === 'biblioteca') p = { tipo: 'dependencia-ausente', mensagem: `O link não achou a biblioteca -l${m[1]}: ela não existe no Emscripten (ligue o port certo ou compile na receita).` };
            else if (r.tipo === 'simbolo') p = { tipo: 'simbolo', mensagem: `Função/variável sem definição no link: ${m[1]} (falta uma biblioteca ou um arquivo no build).` };
            else if (r.tipo === 'cmake') p = { tipo: 'configuracao', mensagem: 'CMake: ' + m[1].trim() };
            else if (r.tipo === 'configure') p = { tipo: 'configuracao', mensagem: 'configure: ' + m[1].trim() };
            else if (r.tipo === 'closure') p = { tipo: 'link', mensagem: `O Closure (otimizador de JS) não conhece "${m[1]}": exporte com -sEXPORTED_RUNTIME_METHODS ou tire o --closure.` };
            else if (r.tipo === 'git') p = { tipo: 'fonte', mensagem: 'git: ' + m[1].trim() };
            else if (r.tipo === 'receita') p = { tipo: 'receita', mensagem: m[1] };
            else p = { tipo: 'compilacao', arquivo: m[1], linha: +m[2], mensagem: `Erro de compilação em ${path.basename(m[1])}:${m[2]}: ${m[3].trim()}` };
            const chave = p.tipo + '|' + (p.cabecalho || p.mensagem);
            if (!vistos.has(chave)) { vistos.add(chave); achados.push(p); }
            break;
        }
        if (achados.length >= max) break;
    }
    // falta de dependência é a causa; o resto costuma ser consequência
    achados.sort((a, b) => (a.tipo === 'dependencia-ausente' ? 0 : 1) - (b.tipo === 'dependencia-ausente' ? 0 : 1));
    return achados;
}

/** Linha de anotação do GitHub Actions (aparece na API de check-runs, que a Studio lê). */
export function anotacao(p) {
    const limpa = s => String(s).replace(/%/g, '%25').replace(/\r/g, '%0D').replace(/\n/g, '%0A');
    const titulo = { 'dependencia-ausente': 'Dependência ausente', simbolo: 'Símbolo indefinido', configuracao: 'Erro de configuração', link: 'Erro no link',
        fonte: 'Erro ao baixar o código', receita: 'Receita incompleta', compilacao: 'Erro de compilação' }[p.tipo] || 'Erro';
    return `::error title=${limpa(titulo)}::${limpa(p.mensagem)}`;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1])) {
    const log = fs.readFileSync(process.argv[2], 'utf8');
    const achados = diagnosticar(log);
    const github = process.argv.includes('--github');
    if (!achados.length) achados.push({ tipo: 'desconhecido', mensagem: 'A compilação falhou, mas nenhuma regra reconheceu o erro: veja o log completo.' });
    for (const p of achados) console.log(github ? anotacao(p) : '• ' + p.mensagem);
    if (github && process.env.GITHUB_STEP_SUMMARY)
        fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, '### Diagnóstico\n\n' + achados.map(p => '- ' + p.mensagem).join('\n') + '\n');
}
