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
