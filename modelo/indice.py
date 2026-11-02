# Gera a página inicial da prateleira (lista + créditos) e o jogos-publicados.json que o Studio pode ler.
import json, sys, os, html
jogos = json.load(open(sys.argv[1], encoding='utf8'))['jogos']
site = sys.argv[2]
base = 'https://cartoonzine.github.io/cartoonzine-jogos/'
prontos = [j for j in jogos if os.path.exists(os.path.join(site, j['id'], 'index.html'))]
for j in prontos:
    j['url'] = base + j['id'] + '/'
    with open(os.path.join(site, j['id'], 'CREDITOS.txt'), 'w', encoding='utf8') as f:
        f.write(f"{j['nome']} ({j.get('ano','')})\nLicença: {j['licenca']}\nCódigo-fonte usado: {j['fonte']}\nProjeto original: {j.get('original','')}\n"
                "Compilado para a web pelo Cartoonzine (github.com/cartoonzine/cartoonzine-jogos), sem modificações no jogo.\n")
json.dump({'jogos': prontos}, open(os.path.join(site, 'jogos-publicados.json'), 'w', encoding='utf8'), ensure_ascii=False, indent=1)
cards = '\n'.join(f'''<div class="j"><a class="t" href="{html.escape(j['id'])}/"><b>▶ {html.escape(j['nome'])}</b></a><span>{html.escape(j['descricao'])}</span>
<small>{html.escape(j['licenca'])} · <a href="{html.escape(j['fonte'])}">código-fonte</a> · <a href="{html.escape(j['id'])}/CREDITOS.txt">créditos</a></small></div>''' for j in prontos)
open(os.path.join(site, 'index.html'), 'w', encoding='utf8').write(f'''<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cartoonzine Jogos</title><style>
body{{margin:0;background:#07070c;color:#e5e7eb;font:15px/1.5 system-ui,sans-serif;padding:32px 16px}}main{{max-width:960px;margin:auto}}h1{{font-size:26px;margin:0 0 4px}}p{{color:#94a3b8;margin:0 0 24px}}
.g{{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:14px}}.j{{display:flex;flex-direction:column;gap:6px;padding:16px;border-radius:12px;background:#11131c;border:1px solid #1f2433;color:inherit;text-decoration:none}}
.j:hover{{border-color:#22d3ee}}.j .t{{color:inherit;text-decoration:none}}.j b{{font-size:17px}}.j span{{color:#cbd5e1;font-size:14px}}.j small{{color:#64748b}}.j small a{{color:#22d3ee}}
</style></head><body><main><h1>🎮 Cartoonzine Jogos</h1><p>Jogos livres (código aberto) compilados para rodar no navegador, sem propaganda. Cada jogo tem os créditos e a licença na própria pasta.</p>
<div class="g">{cards}</div></main></body></html>''')
print(len(prontos), 'jogos no site:', ', '.join(j['id'] for j in prontos))
