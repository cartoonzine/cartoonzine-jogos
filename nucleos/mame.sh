#!/bin/bash
# Constrói UM core do EmulatorJS a partir do MAME atual (versão libretro), só com uma parte dos jogos.
#   ID=mame_capcom FONTES=src/mame/capcom SAIDA=/pasta/de/saida bash mame.sh
# Passos (iguais aos do build oficial do EmulatorJS, github.com/EmulatorJS/build):
#   1. MAME libretro → <ID>_libretro_emscripten.bc  (emmake make -f Makefile.libretro platform=emscripten)
#   2. RetroArch do EmulatorJS junta o core → <ID>-legacy-wasm.data (o arquivo que o EmulatorJS baixa)
#   3. core.json + license.txt + build.json dentro do .data, e o relatório reports/<ID>.json
set -euo pipefail
: "${ID:?falta ID}" "${FONTES:?falta FONTES}" "${SAIDA:?falta SAIDA}"
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OBRA="${OBRA:-/tmp/obra-$ID}"
MAME_REPO="${MAME_REPO:-https://github.com/libretro/mame.git}"
MAME_REF="${MAME_REF:-master}"
JOBS="${JOBS:-$(nproc)}"
mkdir -p "$OBRA" "$SAIDA/reports"
INICIO="$(date -u -Is)"

echo "::group::Baixar o MAME ($MAME_REF)"
cd "$OBRA"
[ -d mame ] || git clone -q --depth 1 --branch "$MAME_REF" "$MAME_REPO" mame
cd mame
VERSAO="$(grep -o 'BARE_BUILD_VERSION "[0-9.]*"' makefile | head -1 | grep -o '[0-9.]*' || echo '?')"
echo "MAME $VERSAO · $(git log -1 --format='%h %cd')"
python3 "$AQUI/mame-web.py" .
echo "::endgroup::"

echo "::group::Compilar o MAME ($FONTES)"
SUB="${ID#mame_}"
# sem DRC nativo (não existe para wasm), sem asm, 32 bits; o resto é o Makefile.libretro de sempre
emmake make -f Makefile.libretro platform=emscripten \
    SUBTARGET="$SUB" SOURCES="$FONTES" \
    REGENIE=1 NOWERROR=1 VERBOSE=0 PYTHON_EXECUTABLE=python3 \
    PTR64=0 NOASM=1 FORCE_DRC_C_BACKEND=1 LIBRETRO_CPU= ARCHITECTURE= \
    OPTIMIZE="${OPTIMIZE:-2}" NO_USE_MIDI=1 NO_USE_PORTAUDIO=1 \
    -j"$JOBS"
BC="$(find . -name '*_libretro_emscripten.bc' -newer makefile -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2- || true)"
[ -n "$BC" ] || { echo "não saiu nenhum *_libretro_emscripten.bc"; ls -la; exit 1; }
ls -la "$BC"
echo "::endgroup::"

echo "::group::Juntar com o RetroArch do EmulatorJS"
cd "$OBRA"
[ -d RetroArch ] || git clone -q --depth 1 https://github.com/EmulatorJS/RetroArch.git RetroArch
cd RetroArch/emulatorjs
rm -f ./*.bc
emar -crs "${ID}_libretro_emscripten.bc" "$OBRA/mame/${BC#./}"
# o MAME usa exceções (precisa do mesmo -fwasm-exceptions na hora de juntar) e bastante memória
python3 - "$ID" <<'PY'
import sys, re
from pathlib import Path
idc = sys.argv[1]
mk = Path('../Makefile.emulatorjs'); s = mk.read_text()
if 'CARTOONZINE-MAME' not in s:
    marca = 'ifneq (,$(findstring same_cdi,$(TARGET)))'
    assert marca in s, 'Makefile.emulatorjs mudou: não achei o bloco do same_cdi'
    s = s.replace(marca, '# CARTOONZINE-MAME: cores do MAME atual (exceções em WebAssembly)\nifneq (,$(findstring mame_,$(TARGET)))\n   LDFLAGS += -fwasm-exceptions\nendif\n\n' + marca, 1)
    mk.write_text(s)
sh = Path('build-emulatorjs.sh'); t = sh.read_text()
# memória grande e sem o 7-Zip do RetroArch (o MAME já traz o dele: os dois juntos dão "duplicate symbol")
for lista in ('largeHeap', 'no7Zip'):
    if idc not in t.split(lista + '=(')[1].split(')')[0]:
        t = t.replace(lista + '=(', f'{lista}=("{idc}" ', 1)
sh.write_text(t)
print('RetroArch ajustado para', idc)
PY
emmake ./build-emulatorjs.sh --clean --legacy
DATA="$OBRA/EmulatorJS/data/cores/${ID}-legacy-wasm.data"
test -f "$DATA"
echo "::endgroup::"

echo "::group::Empacotar"
cd "$OBRA"
FIM="$(date -u -Is)"
cat > core.json <<JSON
{ "name": "$ID", "extensions": ["zip", "7z"], "license": "COPYING", "repo": "$MAME_REPO",
  "options": { "settings": {}, "defaultWebGL2": false, "supportsMouse": false }, "save": false,
  "mame": "$VERSAO", "fontes": "$FONTES" }
JSON
cp mame/COPYING license.txt
echo '{ "minimumEJSVersion": "4.3.0", "version": "2.0.3" }' > build.json
7z a -t7z -bso0 "$DATA" ./core.json ./license.txt ./build.json
cp "$DATA" "$SAIDA/"
echo "{ \"core\": \"$ID\", \"mame\": \"$VERSAO\", \"fontes\": \"$FONTES\", \"buildStart\": \"$INICIO\", \"buildEnd\": \"$FIM\", \"options\": { \"defaultWebGL2\": false } }" > "$SAIDA/reports/$ID.json"
ls -la "$SAIDA" "$SAIDA/reports"
echo "::endgroup::"
