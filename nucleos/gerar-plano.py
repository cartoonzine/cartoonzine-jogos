#!/usr/bin/env python3
"""Plano dos cores do MAME por fabricante, feito a partir do próprio código do MAME.

    python3 nucleos/gerar-plano.py <pasta do mame>

Lê src/mame/mame.lst (qual jogo fica em qual arquivo) e src/mame/arcade.flt (a lista OFICIAL do MAME de
arquivos de arcade, já sem os drivers que não funcionam) e escreve:
  • nucleos/filtros/<core>.flt   – o filtro que o build usa (só os jogos de arcade daquela parte);
  • nucleos/mapa-romsets.json    – romset → core (para separar as ROMs e preencher o Core no Studio);
  • a contagem de jogos de cada parte em nucleos/nucleos.json (o resto do arquivo não é mexido).
Quando sair MAME novo é só rodar de novo.
"""
import json
import re
import sys
from collections import OrderedDict
from pathlib import Path

AQUI = Path(__file__).resolve().parent
MAME = Path(sys.argv[1] if len(sys.argv) > 1 else 'mame')

cfg = json.loads((AQUI / 'nucleos.json').read_text(encoding='utf-8'))
versao = re.search(r'BARE_BUILD_VERSION "([0-9.]+)"', (MAME / 'makefile').read_text(encoding='utf-8'))
versao = versao.group(1) if versao else '?'

# jogos de cada arquivo-fonte
lst, cur = {}, None
for linha in (MAME / 'src/mame/mame.lst').read_text(encoding='utf-8').splitlines():
    linha = linha.split('//')[0].strip()
    if linha.startswith('@source:'):
        cur = linha[8:]; lst[cur] = []
    elif linha and cur:
        lst[cur].append(linha)

# arcade.flt: arquivo e as exclusões (-jogo) que vêm logo depois dele
blocos = OrderedDict()
atual = None
for bruta in (MAME / 'src/mame/arcade.flt').read_text(encoding='utf-8').splitlines():
    linha = bruta.strip()
    if not linha or linha.startswith('//'):
        continue
    linha = linha.split('//')[0].strip()
    if linha.startswith('-'):
        if atual:
            blocos[atual].append(linha[1:].strip())
    else:
        atual = linha
        blocos[atual] = []

pasta_do_core = {}
for n in cfg['nucleos']:
    for p in n['pastas']:
        if p in pasta_do_core:
            sys.exit(f'a pasta {p} está em dois cores: {pasta_do_core[p]} e {n["id"]}')
        pasta_do_core[p] = n['id']

sem_core = sorted({f.split('/')[0] for f in blocos} - set(pasta_do_core))
if sem_core:
    sys.exit('pastas de arcade sem core no nucleos.json: ' + ', '.join(sem_core))

(AQUI / 'filtros').mkdir(exist_ok=True)
mapa, contagem = {}, {n['id']: 0 for n in cfg['nucleos']}
filtros = {n['id']: [f'// {n["nome"]} · MAME {versao} · gerado por nucleos/gerar-plano.py a partir do src/mame/arcade.flt'] for n in cfg['nucleos']}
for arquivo, fora in blocos.items():
    core = pasta_do_core[arquivo.split('/')[0]]
    filtros[core].append(arquivo)
    filtros[core].extend('-' + x for x in fora)
    for jogo in lst.get(arquivo, []):
        if jogo in fora:
            continue
        mapa[jogo] = core
        contagem[core] += 1

for core, linhas in filtros.items():
    (AQUI / 'filtros' / f'{core}.flt').write_text('\n'.join(linhas) + '\n', encoding='utf-8')
(AQUI / 'mapa-romsets.json').write_text(json.dumps(
    {'_comentario': f'romset (nome do .zip) → core. MAME {versao}. Jogo que não está aqui não é de arcade ou o MAME marca como não funcionando.',
     'mame': versao, 'romsets': dict(sorted(mapa.items()))}, ensure_ascii=False, indent=0) + '\n', encoding='utf-8')

texto = (AQUI / 'nucleos.json').read_text(encoding='utf-8')
for core, n in contagem.items():
    texto = re.sub(r'("id": "%s"[^\n]*?"jogos": )\d+' % re.escape(core), lambda m: m.group(1) + str(n), texto)
texto = re.sub(r'"versaoMame": "[^"]*"', f'"versaoMame": "{versao}"', texto)
(AQUI / 'nucleos.json').write_text(texto, encoding='utf-8')
print(f'MAME {versao}: {len(mapa)} jogos de arcade em {len(contagem)} cores')
for n in cfg['nucleos']:
    print(f'  {n["id"]:24} {contagem[n["id"]]:5} jogos  fase {n["fase"]}  {"✅" if n.get("construir") else "·"}')
