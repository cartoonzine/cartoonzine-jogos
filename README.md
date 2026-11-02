# 🎮 Cartoonzine Jogos

Prateleira de **jogos web livres** (código aberto) para o cartucho web do Cartoonzine.
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

## 🕹️ Cores do MAME atual para o EmulatorJS (`nucleos/`)

O MAME inteiro é grande demais para o navegador, então ele vira **vários cores, um por parte** (pasta de fabricante
em `src/mame/<fabricante>`). Cada parte está em `nucleos/nucleos.json`:

| core | jogos | MAME |
|---|---|---|
| `mame_capcom` | Capcom (`src/mame/capcom`: CPS1, CPS2, CPS3, 1942, Ghosts'n Goblins…) | 0.289 |

- **Construir:** Actions → *Construir os cores do MAME* → *Run workflow* (vazio = todos). Também roda sozinho quando
  muda algo em `nucleos/`. Leva uns 30 minutos por parte. Sai em `gh-pages/cores/`.
- **Parte nova:** acrescente uma linha em `nucleos.json` (ex.: `{ "id": "mame_snk", "nome": "MAME (SNK)", "fontes": "src/mame/snk" }`).
  O id precisa começar com `mame_`.
- **No app:** o jogo usa o core pelo campo *Core do emulador* do Studio (ex.: `mame_capcom`). A ROM precisa ser do
  romset da mesma versão do MAME e o link tem que terminar com o nome do romset (`…/sf2.zip`).
- Como é feito: `nucleos/mame-web.py` faz no MAME versão libretro os mesmos ajustes que o EmulatorJS fez no core
  `same_cdi`; `nucleos/mame.sh` compila com o emscripten e junta com o RetroArch do EmulatorJS, igual ao
  [build oficial](https://github.com/EmulatorJS/build).
