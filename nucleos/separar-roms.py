#!/usr/bin/env python3
"""Separa uma pasta de ROMs do MAME por core (o mesmo jeito dos cores do Cartoonzine).

    python3 separar-roms.py PASTA_DAS_ROMS PASTA_DE_SAIDA            (só mostra o que faria)
    python3 separar-roms.py PASTA_DAS_ROMS PASTA_DE_SAIDA --copiar   (copia)
    python3 separar-roms.py PASTA_DAS_ROMS PASTA_DE_SAIDA --mover    (move: mais rápido, não duplica espaço)

Resultado:
    PASTA_DE_SAIDA/mame_capcom/sf2.zip, PASTA_DE_SAIDA/mame_snk/mslug.zip, …
    PASTA_DE_SAIDA/_sem-core/…      (BIOS/dispositivos que nenhum core lista, jogos que não são de arcade ou não funcionam)
    PASTA_DE_SAIDA/lista-por-core.csv  (romset, core, arquivo, chd: dá para importar no Cartoonzine Studio)
Pastas de CHD (um diretório com o nome do romset, ex.: sfiii/cap-sf3-3.chd) vão junto com o jogo, e os .chd entram
na coluna "chd" da linha do jogo (o Studio põe no campo "Disco do jogo (CHD)" e o cartucho baixa junto).
Usa o nucleos/mapa-romsets.json (gerado do MAME pelo gerar-plano.py): use ROMs da MESMA versão do MAME.
"""
import csv
import json
import shutil
import sys
from collections import Counter
from pathlib import Path

AQUI = Path(__file__).resolve().parent
args = [a for a in sys.argv[1:] if not a.startswith('--')]
if len(args) != 2:
    sys.exit(__doc__)
origem, destino = Path(args[0]), Path(args[1])
modo = 'mover' if '--mover' in sys.argv else 'copiar' if '--copiar' in sys.argv else 'simular'
dados = json.loads((AQUI / 'mapa-romsets.json').read_text(encoding='utf-8'))
mapa = dados['romsets']

itens = sorted(p for p in origem.iterdir() if p.suffix.lower() in ('.zip', '.7z') or p.is_dir())
cont, linhas = Counter(), []
for p in itens:
    romset = p.stem if p.is_file() else p.name
    core = mapa.get(romset, '_sem-core')
    cont[core] += 1
    alvo = destino / core / p.name
    if p.is_file():
        pasta = origem / romset            # CHDs do jogo: PASTA/<romset>/*.chd
        discos = sorted(c.name for c in pasta.glob('*.chd')) if pasta.is_dir() else []
        linhas.append((romset, core, f'{core}/{p.name}', ' '.join(f'{core}/{romset}/{c}' for c in discos)))
    if modo == 'simular' or alvo.exists():
        continue
    alvo.parent.mkdir(parents=True, exist_ok=True)
    if modo == 'mover':
        shutil.move(str(p), str(alvo))
    elif p.is_dir():
        shutil.copytree(p, alvo)
    else:
        shutil.copy2(p, alvo)

if modo != 'simular':
    destino.mkdir(parents=True, exist_ok=True)
    with open(destino / 'lista-por-core.csv', 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f); w.writerow(['romset', 'core', 'arquivo', 'chd']); w.writerows(linhas)
print(f'MAME {dados["mame"]} · {len(itens)} itens em {origem} · modo: {modo}')
for core, n in sorted(cont.items(), key=lambda x: -x[1]):
    print(f'  {core:24} {n:6}')
if modo == 'simular':
    print('Nada foi mexido. Para fazer de verdade: --copiar ou --mover')
