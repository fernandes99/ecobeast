"""Confere o tamanho das folhas da luta de um Ecobeast (board-battle/41). Sai com código 1 se falhar.

Uso: python check_battle.py <slug> [zip do PixelLab]

Confere o canvas dos zips do PixelLab em art-source/<slug>/ (ou só o zip passado, antes de
trazê-lo para o jogo) e as folhas de client/assets/creatures/<slug>/battle/. A altura vem do
catálogo do servidor, em ECOBEAST_API_URL (padrão http://localhost:3100), que precisa estar no ar.
"""
import json
import os
import sys
import urllib.error
import urllib.request
import zipfile
from pathlib import Path

# Com `python -I`, a pasta do script não entra na busca de módulos.
sys.path.insert(0, str(Path(__file__).resolve().parent))

from spritekit import read_png  # noqa: E402

API_URL = os.environ.get("ECOBEAST_API_URL", "http://localhost:3100")
ROOT = Path(__file__).resolve().parents[4]
MAX_WIDTH = 96
HAND_MIN = 0.6
IDLE_ROWS = (2, 5)
WALK_ROWS = (3, 5)
ZIP_SHEETS = {"pixellab.zip": ("idle", "walk"), "pixellab_idle.zip": ("idle",), "pixellab_walk.zip": ("walk",)}


def battle_canvas(height_m):
    if height_m <= 0.6:
        return 48
    if height_m <= 1.0:
        return 64
    return 80 if height_m <= 2.0 else 96


def catalog_height(slug):
    try:
        with urllib.request.urlopen(API_URL + "/v1/catalog", timeout=10) as response:
            species = json.load(response)["tables"]["species"]
    except (urllib.error.URLError, OSError):
        print("FALHA: o servidor precisa estar no ar para ler as alturas do catálogo (%s)" % API_URL)
        sys.exit(1)
    for row in species:
        if row["slug"] == slug:
            return float(row["height_m"])
    print("FALHA: %s não está no catálogo" % slug)
    sys.exit(1)


def zip_canvases(path):
    """Os canvas dos personagens do zip: a exportação em pastas tem o metadata.json, e a folha só, o <nome>.json."""
    sizes = set()
    with zipfile.ZipFile(path) as archive:
        for name in archive.namelist():
            if not name.endswith(".json"):
                continue
            data = json.loads(archive.read(name))
            states = data.get("states") or [data]
            for state in states:
                character = state.get("character") if isinstance(state, dict) else None
                if character and "size" in character:
                    sizes.add(int(character["size"]["height"]))
    return sizes


def find_cell(idle_height, walk_height):
    """Como o BattleSheets._find_rows do jogo."""
    for idle_rows in IDLE_ROWS:
        for walk_rows in WALK_ROWS:
            if idle_height % idle_rows == 0 and idle_height * walk_rows == walk_height * idle_rows:
                return idle_height // idle_rows
    return None


def measure(path, cell):
    """(altura, largura) do maior desenho entre os quadros."""
    width, height, rows = read_png(path)
    tallest = widest = 0
    for top in range(0, height, cell):
        for left in range(0, width - cell + 1, cell):
            xs = []
            ys = []
            for y in range(cell):
                line = rows[top + y]
                for x in range(cell):
                    if line[(left + x) * 4 + 3]:
                        xs.append(x)
                        ys.append(y)
            if xs:
                tallest = max(tallest, max(ys) - min(ys) + 1)
                widest = max(widest, max(xs) - min(xs) + 1)
    return tallest, widest


def check_zip(path, canvas, errors):
    sizes = zip_canvases(path)
    print("%s: canvas %s" % (path.name, ", ".join(str(size) for size in sorted(sizes)) or "não achado"))
    if sizes != {canvas}:
        errors.append("%s: canvas %s, e a regra pede %d" % (path.name, sorted(sizes), canvas))


def check_sheets(slug, canvas, errors):
    folder = ROOT / "client" / "assets" / "creatures" / slug / "battle"
    paths = {name: folder / (name + ".png") for name in ("idle", "walk")}
    if not all(path.exists() for path in paths.values()):
        print("sem as duas folhas em %s" % folder)
        return
    cell = find_cell(read_png(paths["idle"])[1], read_png(paths["walk"])[1])
    if cell is None:
        errors.append("as linhas das folhas não fecham numa célula só (idle com 2 ou 5, walk com 3 ou 5)")
        return
    from_zip = set()
    for name, sheets in ZIP_SHEETS.items():
        if (ROOT / "art-source" / slug / name).exists():
            from_zip.update(sheets)
    low = round(canvas * HAND_MIN)
    for name, path in paths.items():
        tallest, widest = measure(path, cell)
        origin = "do PixelLab" if name in from_zip else "à mão, faixa de %d a %d" % (low, canvas)
        print("%s: %d px de altura, %d px de largura, célula %d (%s)" % (name, tallest, widest, cell, origin))
        if name not in from_zip and not low <= tallest <= canvas:
            errors.append("%s: %d px de altura, fora da faixa de %d a %d do canvas %d" % (name, tallest, low, canvas, canvas))
        if widest > MAX_WIDTH:
            errors.append("%s: %d px de largura, o limite é %d" % (name, widest, MAX_WIDTH))


def main():
    slug = sys.argv[1]
    height_m = catalog_height(slug)
    canvas = battle_canvas(height_m)
    print("%s: %.2f m, canvas %d no PixelLab" % (slug, height_m, canvas))
    errors = []
    if len(sys.argv) > 2:
        check_zip(Path(sys.argv[2]), canvas, errors)
    else:
        for name in ZIP_SHEETS:
            path = ROOT / "art-source" / slug / name
            if path.exists():
                check_zip(path, canvas, errors)
        check_sheets(slug, canvas, errors)
    for error in errors:
        print("FALHA:", error)
    print("RESULTADO:", "FALHOU" if errors else "PASSOU")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
