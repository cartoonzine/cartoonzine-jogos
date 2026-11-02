# Ajusta a página do Neverball para o cartucho web: só o jogo, em tela cheia, abrindo direto.
import sys
p = sys.argv[1]
s = open(p, encoding='utf8').read()
css = '''<style id="cz-tela-cheia">
  /* Cartoonzine: só o jogo, ocupando a tela toda do cartucho */
  html, body { overflow: hidden !important; background: #000 !important; }
  #canvas { position: fixed !important; inset: 0 !important; width: 100vw !important; height: 100vh !important; max-width: none !important; max-height: none !important; z-index: 2147483000 !important; display: block !important; }
</style>
'''
js = '''<script>
// Cartoonzine: abre direto no jogo (sem a tela "Play Now"), quando o launcher estiver pronto
(function () { var n = 0, t = setInterval(function () { var b = document.getElementById('run-button');
  if (b && !b.disabled && !document.body.classList.contains('in-game')) { clearInterval(t); b.click(); } if (++n > 600) clearInterval(t); }, 100); })();
</script>
'''
if 'cz-tela-cheia' not in s:
    i = s.index('</head>'); s = s[:i] + css + s[i:]
    i = s.rindex('</body>'); s = s[:i] + js + s[i:]
open(p, 'w', encoding='utf8').write(s)
print('neverball: tela cheia + abre direto')
