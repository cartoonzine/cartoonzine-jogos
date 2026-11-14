# 🕹️ Plano dos cores do MAME 0.289 por fabricante

O MAME inteiro não cabe no navegador, então ele vira **21 cores**: um por fabricante grande, e os pequenos juntos.
São **13.339 jogos de arcade** (contando as versões de cada jogo), tirados da lista oficial do MAME
(`src/mame/arcade.flt`, que já deixa de fora o que o MAME marca como não funcionando).

**Situação (14/11/2026):** os **21 cores** estão construídos e publicados em `gh-pages/cores/` (MAME 0.289, tag
`lrmame0289` do libretro/mame). ✅ = construído; falta testar jogos de cada um no app.

**Passo a passo para cada core novo:**
1. Em `nucleos/nucleos.json`, troque `"construir": false` por `true` no core.
2. Actions → **Construir os cores do MAME** → *Run workflow* → escreva o id (ex.: `mame_snk`) ou vários separados por vírgula
   (`mame_konami,mame_sega`). Vazio = todos com `construir: true`. Leva uns 30 a 60 minutos (os vários rodam em paralelo).
3. Teste um jogo no app (campo **Core do emulador** no Studio = id do core) e marque aqui ✅.

| | core | jogos | fabricantes (pastas do MAME) | exemplos |
|---|---|---:|---|---|
| **Fase 1 · os mais jogados** | | | | |
| ✅ | `mame_capcom` | 834 | capcom | Street Fighter, Final Fight, CPS1/CPS2/CPS3 |
| ✅ | `mame_snk` | 422 | snk | Metal Slug, King of Fighters, Samurai Shodown |
| ✅ | `mame_konami` | 835 | konami | TMNT, X-Men, Simpsons, Gradius |
| ✅ | `mame_sega` | 1172 | sega | Out Run, Golden Axe, System 16/18/24/32 (Model 2/3 e Naomi são pesados) |
| ✅ | `mame_namco` | 501 | namco | Pac-Mania, Galaga 88, System 1/2 (System 22/23 são pesados) |
| ✅ | `mame_taito` | 730 | taito | Bubble Bobble, Darius, Space Invaders, F3 |
| **Fase 2 · clássicos e arcades famosos** | | | | |
| ✅ | `mame_dataeast` | 453 | dataeast | Bad Dudes, Captain America, Joe & Mac |
| ✅ | `mame_irem` | 200 | irem | R-Type, Kung-Fu Master, In the Hunt |
| ✅ | `mame_midway` | 406 | williams, bally, midcoin | Defender, Robotron, Joust |
| ✅ | `mame_classicos` | 1188 | galaxian, pacman, midw8080, cinematronics, exidy, gottlieb e mais 11 | Pac-Man, Galaxian, Frogger, Q*bert |
| ✅ | `mame_shmups` | 548 | toaplan, psikyo, cave, seibu, nmk | Truxton, DoDonPachi, Raiden |
| ✅ | `mame_nintendo` | 281 | nintendo | Donkey Kong, Punch-Out!!, VS. System |
| **Fase 3 · o resto dos fabricantes grandes** | | | | |
| ✅ | `mame_atari` | 474 | atari | Gauntlet, Paperboy, Rampart |
| ✅ | `mame_nichibutsu_jaleco` | 615 | nichibutsu, jaleco, tecmo, technos | Double Dragon, Ninja Gaiden, Rygar |
| ✅ | `mame_kaneko_seta` | 658 | kaneko, seta, metro, fuuki, unico, tatsumi e mais 6 | Air Buster, Blandia |
| ✅ | `mame_coreia_europa` | 484 | gaelco, yunsung, dooyong, playmark, suna, eolith e mais 5 | Aero Fighters, World Rally |
| ✅ | `mame_sony_itech` | 379 | sony, itech, atlus | Golden Tee, jogos em placa de PlayStation (pesados) |
| ✅ | `mame_igs` | 658 | igs | Knights of Valour, PGM |
| **Fase 4 · diversos, raridades e cassino** | | | | |
| ✅ | `mame_diversos` | 1310 | misc | fabricantes pequenos que o MAME guarda juntos |
| ✅ | `mame_outros` | 398 | dynax, amiga, ice, philips, bordun, alliedleisure e mais 23 | Dynax (mahjong) e placas raras |
| ✅ | `mame_cassino` | 793 | amcoe, merit, funworld, aristocrat, astrocorp, subsino e mais 11 | máquinas de aposta (baixa prioridade) |

⚠️ Placas 3D (Sega Model 2/3 e Naomi, Namco System 22/23, Konami Hornet, Sony ZN) podem ficar lentas no navegador.

## ROMs separadas do mesmo jeito

- **Use ROMs da mesma versão do MAME** do core (hoje 0.289). ROM de outra versão pode não abrir.
- **Prefira o romset "non-merged"**: cada .zip tem tudo que o jogo precisa, inclusive o que vem do jogo "pai".
  O app manda **um arquivo por jogo**, então é o único formato em que qualquer versão (ex.: `sf2ce`) abre sozinha.
  - *split*: a versão (clone) só tem as diferenças e precisa do .zip do pai junto → o app ainda não manda dois arquivos.
  - *merged*: todas as versões dentro do .zip do pai → o app não tem como escolher qual versão abrir.
- **BIOS**: alguns sistemas precisam de um .zip de BIOS além do jogo (ex.: `neogeo.zip` na SNK). Isso entra no app junto
  com o core da SNK.
- **CHD** (disco, ex.: CPS3 `sfiii`): fica numa pasta com o nome do jogo e o `separar-roms.py` já leva junto com o .zip.
  **Ainda não abre no app** (o cartucho manda um arquivo só). Próximo passo: o cartucho baixar o `.chd` junto pelo
  `EJS_externalFiles` do EmulatorJS (no caminho onde o MAME procura), campo "Arquivo de disco (CHD)" no Studio e a
  importação em massa/separador preenchendo esse campo. Afeta CPS3, Konami System 573, Naomi GD-ROM e outras placas com disco.
- **Separar por core:** `python3 nucleos/separar-roms.py PASTA_DAS_ROMS PASTA_SAIDA --copiar` (ou `--mover`) cria uma pasta
  por core (`mame_capcom/`, `mame_snk/`…) e o `lista-por-core.csv` (romset → core). Sem `--copiar/--mover` ele só mostra.
- **Link do jogo no Studio:** tem que terminar com o nome do romset (`…/sf2.zip`).

## Quando sair MAME novo

`python3 nucleos/gerar-plano.py <pasta do mame>` refaz os filtros (`nucleos/filtros/*.flt`), o `mapa-romsets.json` e a
contagem de jogos. Depois é só construir de novo os cores marcados.
