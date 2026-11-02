#!/usr/bin/env python3
"""Ajustes no MAME versão libretro para compilar como core do EmulatorJS (emscripten).

Os mesmos ajustes que o EmulatorJS fez no same_cdi (MAME do CD-i), atualizados para o MAME atual:
  1. retro.lua: não linka "util" no emscripten (não existe lá);
  2. machine.cpp/.h: o laço de JavaScript do MAME web não entra no libretro (quem manda é o RetroArch);
  3. genie.lua: o bloco asmjs fica só com o que serve para um core libretro (sem SDL, sem --embed-file);
  4. main.lua / toolchain.lua: tira as opções velhas de exceção e o "finalize" que tentava virar .html;
  5. exceções em WebAssembly (-fwasm-exceptions): o MAME usa exceções de verdade (erros de ROM, etc.);
  6. sol2: um template que o clang novo não aceita (mesmo ajuste do same_cdi).
Uso: python3 mame-web.py <pasta do mame>
"""
import re
import sys
from pathlib import Path

RAIZ = Path(sys.argv[1] if len(sys.argv) > 1 else '.')
EXC = '-fwasm-exceptions'
problemas = []


def editar(rel, func):
    p = RAIZ / rel
    s = p.read_text(encoding='utf-8')
    novo = func(s)
    if novo != s:
        p.write_text(novo, encoding='utf-8')
        print(f'  ✔ {rel}')
    else:
        print(f'  = {rel} (já estava)')


def trocar(s, velho, novo, rel, obrigatorio=True):
    if novo in s and velho not in s:
        return s
    if velho not in s:
        if obrigatorio:
            problemas.append(f'{rel}: não achei o trecho: {velho[:70]!r}')
        return s
    return s.replace(velho, novo)


# 1. retro.lua
def retro_lua(s):
    rel = 'scripts/src/osd/retro.lua'
    return trocar(s, '\t\t\telse\n\t\t\t\tlinks {\n\t\t\t\t\t"util",',
                  '\t\t\telseif _OPTIONS["targetos"]~="asmjs" then\n\t\t\t\tlinks {\n\t\t\t\t\t"util",', rel)
editar('scripts/src/osd/retro.lua', retro_lua)


# 2. machine.cpp / machine.h
def machine(rel):
    def f(s):
        return re.sub(r'#if defined\(__EMSCRIPTEN__\)\n(?=\s*(// break out|private:))',
                      '#if defined(__EMSCRIPTEN__) && !defined(__LIBRETRO__)\n', s)
    return f
editar('src/emu/machine.cpp', machine('src/emu/machine.cpp'))
editar('src/emu/machine.h', machine('src/emu/machine.h'))
for rel in ('src/emu/machine.cpp', 'src/emu/machine.h'):
    t = (RAIZ / rel).read_text(encoding='utf-8')
    if re.search(r'#if defined\(__EMSCRIPTEN__\)\n', t):
        problemas.append(f'{rel}: ainda tem #if defined(__EMSCRIPTEN__) sem o !__LIBRETRO__')


# 3. genie.lua: bloco asmjs enxuto
def genie(s):
    rel = 'scripts/genie.lua'
    ini = s.find('\nconfiguration { "asmjs" }\n\tbuildoptions {')
    fim = s.find('\nconfiguration { "android*" }', ini)
    if ini < 0 or fim < 0:
        if 'CARTOONZINE-WEB' not in s:
            problemas.append(f'{rel}: não achei o bloco asmjs')
        return s
    bloco = ('\n-- CARTOONZINE-WEB: core libretro para o EmulatorJS (sem SDL, sem arquivos embutidos)\n'
             'configuration { "asmjs" }\n'
             '\tbuildoptions {\n\t\t"-Wno-implicit-function-declaration",\n\t\t"' + EXC + '",\n\t}\n'
             '\tbuildoptions_cpp {\n\t\t"-std=c++20",\n\t}\n'
             '\tdefines {\n\t\t"ASIO_HAS_PTHREADS",\n\t\t"SOUND_DISABLE_THREADING",\n\t}\n'
             '\tlinkoptions {\n\t\t"' + EXC + '",\n\t}\n'
             '\tarchivesplit_size "20"\n')
    return s[:ini] + bloco + s[fim:]
editar('scripts/genie.lua', genie)


# 4a. main.lua: opções velhas de exceção do libretro/asmjs
def main_lua(s):
    rel = 'scripts/src/main.lua'
    return re.sub(r'(elseif _OPTIONS\["targetos"\]=="asmjs" then\n\t+targetsuffix "_libretro_emscripten"\n\t+linkoptions \{)(.*?)(\})',
                  lambda m: m.group(1) + '\n\t\t\t\t"' + EXC + '",\n\t\t\t' + m.group(3), s, count=1, flags=re.S)
editar('scripts/src/main.lua', main_lua)
if 'EXCEPTION_CATCHING_WHITELIST=\'' in (RAIZ / 'scripts/src/main.lua').read_text(encoding='utf-8').split('_libretro_emscripten')[1][:400]:
    problemas.append('scripts/src/main.lua: opções velhas de exceção continuam no libretro/asmjs')


# 4b. toolchain.lua: sem o "finalize" que tentava gerar .html do core
def toolchain(s):
    return re.sub(r'\n\tconfiguration \{ "asmjs" \}\n\t\tpostbuildcommands \{\n\t\t\t"\$\(SILENT\) echo Running asmjs finalize\.",.*?\n\t\t\}\n',
                  '\n', s, count=1, flags=re.S)
editar('scripts/toolchain.lua', toolchain)
if 'Running asmjs finalize' in (RAIZ / 'scripts/toolchain.lua').read_text(encoding='utf-8'):
    problemas.append('scripts/toolchain.lua: o finalize do asmjs continua')


# 6. sol2
def sol2(s):
    return trocar(s, '\t\t\t*this = nullopt;\n\t\t\tthis->construct(std::forward<Args>(args)...);\n\t\t\treturn value();',
                  '\t\t\t*this = nullopt;\n\t\t\tnew (static_cast<void*>(this)) optional(std::in_place, std::forward<Args>(args)...);\n\t\t\treturn **this;',
                  '3rdparty/sol2/sol/sol.hpp', obrigatorio=False)
editar('3rdparty/sol2/sol/sol.hpp', sol2)

if problemas:
    print('\n'.join('  ✘ ' + p for p in problemas))
    sys.exit(1)
print('MAME pronto para o emscripten')
