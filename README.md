# 🎮 Cartoonzine Jogos

Prateleira de **jogos web** para o cartucho web do Cartoonzine.
Cada jogo é **compilado do código-fonte original** pelo GitHub Actions e publicado sem propaganda em:

```
https://cartoonzine.github.io/cartoonzine-jogos/<id>/
```

| Jogo | Licença |
|---|---|
| Jump 'n Bump | GPL-2.0 |
| OpenTyrian | GPL-2.0 (motor) · Tyrian 2.1 freeware (dados) |
| Vectoroids | GPL-2.0 |
| Freegemas | GPL-2.0 |
| XGalaga | GPL-2.0 |
| Neverball | GPL-2.0 |

Cada pasta publicada tem `LICENCA.txt`, `CREDITOS.txt` e `FONTE.txt` (o commit exato usado).

## Pôr um jogo novo
1. Confira que o **jogo inteiro** é livre (código E gráficos/sons), não só o programa.
2. Acrescente o jogo em `jogos.json` e crie `receitas/<id>.sh` (veja as outras).
3. Commit: o robô compila e publica. Depois cadastre no Cartoonzine Studio
   (console Web Games, licença **livre**, link acima).

Rodar só um jogo: *Actions → Construir e publicar os jogos → Run workflow* e escreva o id.

## 🧩 Prateleira (Studio) → validação → publicação

A tela **🧩 Prateleira** do Cartoonzine Studio analisa o link do GitHub de um jogo **só com regras** (sem IA) e grava
uma **receita candidata** (`receitas/<id>.sh`) + a ficha com `"rascunho": true`, o `"commit"` exato analisado e os
`"ajustes"` estruturados (subpasta, alvo, pastas de dados, opções do CMake/configure, flags conferidas por lista branca).

| Estado (na Studio) | O que quer dizer |
|---|---|
| 🔎 revisão necessária | as regras acharam algo sem solução conhecida (ex.: ALUT/GLU sem port, build desconhecido, sem licença) |
| 📝 candidata | receita gerada, ainda não validada (ou mudou depois da última validação) |
| ⚙️ validando | o workflow **Validar receita** está rodando |
| ❌ falhou | configuração, compilação, link, artefatos ou teste no navegador falharam (resumo + link do log) |
| ✅ pronta | validada; ainda é rascunho até alguém clicar **Publicar** e reconfirmar a licença dos dados |

**Validar receita** (`.github/workflows/validar.yml`) roda quando `receitas/**` ou `jogos.json` mudam (só os jogos que
mudaram) ou na mão (*Run workflow* com o id — é o botão "Validar de novo" da Studio, que precisa de token com
**Actions: Read and write**):
1. `compilar (<id>)` — contêiner `emscripten/emsdk:<versão fixa>` (campo `"emsdk"` da ficha, padrão `3.1.74`),
   checkout **sem credenciais**, permissão só de leitura, nenhum secret. Erro em qualquer etapa = job falha;
   `modelo/diagnostico.mjs` transforma o log em anotações (ex.: *Falta AL/alut.h — ALUT, sem port no Emscripten*).
2. `modelo/verificar-saida.mjs` — index.html → .js → .wasm (precisa ser WebAssembly de verdade) → .data, pastas de dados
   declaradas dentro do pacote, `FONTE.txt` com o commit.
3. `navegador (<id>)` — `modelo/testar-navegador.mjs` abre o jogo num Chromium sem tela (Playwright 1.48.2) e exige que
   o `main()` comece sem erro de página, sem `Aborted(` e sem 404. **Não joga o jogo**: travar depois de abrir passa.

Nada disso publica: **Construir e publicar** só compila fichas sem `rascunho`. Nele os jobs de compilação também são
só leitura e sem credenciais; só o job `publicar` (que não roda código dos jogos) tem `contents: write`, e ele só
recebe pastas que passaram por `verificar-saida.mjs`.

Funções das receitas (`receitas/comum.sh`): `baixar_commit <repo> <sha> [submodulos]`, `publicar_jogo <pasta> <alvo> <título> [dados…]`
(para com `REVISAO:` em vez de chutar quando há mais de um `.wasm`), `empacotar_dados`, `moldurar`. As receitas
antigas, feitas à mão, ainda usam `baixar_fonte`/`publicar_saida` e algumas têm `make -k || true` antes de um link
manual — funcionam (o link falha se faltar algo), mas não seguem o padrão novo.

Testes: `node --test testes/*.test.mjs` (diagnóstico com logs reais — inclusive o do AstroMenace —, conferência de
artefatos, `set -euo pipefail` sem `|| true` escondendo erro, `publicar_jogo`/`baixar_commit`).

## 💾 Cartucho DOS (`paginas/dos/`)

Abre jogos de **MS-DOS** direto, em tela cheia, sem logo nem botões de emulador (como os jogos web):

```
https://cartoonzine.github.io/cartoonzine-jogos/dos/?jogo=<link do .zip ou .jsdos>
```

- `jogo`: `.zip` com os arquivos do jogo, ou um pacote `.jsdos` (js-dos / DOS.Zone).
- `cmd` (opcional): o comando que abre o jogo (ex.: `KEEN4E.EXE`). Sem ele a página escolhe sozinha
  (`AUTORUN.BAT` → o `.exe`/`.com`/`.bat` principal). `pasta`, `ciclos` e `esticar=1` também são aceitos.
- Motor: js-dos 7 (DOSBox em WebAssembly, GPL-2.0) em `paginas/dos/jsdos/` (veja `FONTE.txt`).
- Os jogos **não** ficam neste repositório: a página só abre o link que o Cartoonzine passar.
- Publicação: o workflow `paginas.yml` copia `paginas/*` para o `gh-pages` (não recompila os jogos).

## 🖥️ Cartucho PC Classics (`paginas/pc/`)

Jogos antigos de PC (**Windows 95/98**, Windows 3.11 e DOS) direto, em tela cheia, sem logo nem botões:

```
https://cartoonzine.github.io/cartoonzine-jogos/pc/?jogo=<link do pacote .jsdos>
```

- `jogo`: pacote `.jsdos` (Game Studio do js-dos ou DOS.Zone). O Windows vem pelo *sockdrive* do js-dos.
- `motor` (`dosboxX` padrão / `dosbox`), `aspecto` (`4/3` padrão, `16/9`, `Fit`…), `mouse=1` (prende o mouse).
- Motor: js-dos 8.5.3 (GPL-2.0) em `paginas/pc/jsdos8/`, vindo do npm pelo workflow `vendor-jsdos8.yml`.

## 🕹️ Cores do MAME atual para o EmulatorJS (`nucleos/`)

O MAME inteiro é grande demais para o navegador, então ele vira **21 cores, um por fabricante** (os pequenos juntos).
O plano completo, com a ordem de construção e como separar as ROMs, está em **[nucleos/PLANO.md](nucleos/PLANO.md)**.

- `nucleos/nucleos.json`: a lista dos cores (`"construir": true` = o GitHub Actions constrói).
- `nucleos/filtros/*.flt`: quais jogos entram em cada core (tirado do `src/mame/arcade.flt` oficial).
- `nucleos/mapa-romsets.json`: romset → core. `nucleos/separar-roms.py` usa ele para separar uma pasta de ROMs.
- `nucleos/gerar-plano.py`: refaz tudo isso quando sair MAME novo.
- `nucleos/mame-web.py` + `nucleos/mame.sh`: compilam o MAME versão libretro com o emscripten e juntam com o RetroArch
  do EmulatorJS (os mesmos ajustes que o EmulatorJS fez no core `same_cdi`; [build oficial](https://github.com/EmulatorJS/build)).
- Sai em `gh-pages/cores/`; o `cartucho.html` do app busca de lá qualquer core que começa com `mame_`.
