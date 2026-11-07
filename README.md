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
