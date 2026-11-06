"""Confere as folhas de uma criatura. Sai com código 1 se alguma regra falhar.

Uso: python check_sheets.py <pasta da criatura>

A pasta tem o slug da criatura: é por ele que a altura vem do catálogo.
"""
import json
import sys
from pathlib import Path

# Com `python -I`, a pasta do script não entra na busca de módulos.
sys.path.insert(0, str(Path(__file__).resolve().parent))

from spritekit import CELL, FRAMES, VIEWS, height_in_pixels, read_png  # noqa: E402

SEED = Path(__file__).resolve().parents[4] / "server/prisma/seed-data/species.json"
# A chama de um quadro ou a ponta de uma orelha podem mudar a conta em um pixel.
HEIGHT_MARGIN = 1


def cell_of(rows, view, frame):
    return [rows[view * CELL + y][frame * CELL * 4:(frame + 1) * CELL * 4] for y in range(CELL)]


def box(cell):
    xs = []
    ys = []
    for y, line in enumerate(cell):
        for x in range(CELL):
            if line[x * 4 + 3]:
                xs.append(x)
                ys.append(y)
    return (min(xs), max(xs), min(ys), max(ys)) if xs else None


def expected_height(slug):
    """Em pixels; None se a pasta não for de um Ecobeast do catálogo."""
    for row in json.loads(SEED.read_text(encoding="utf-8")):
        if row["slug"] == slug:
            return height_in_pixels(row["height_m"])
    return None


def check(path, name, height):
    errors = []
    frames = FRAMES[name]
    width, sheet_height, rows = read_png(path)
    if (width, sheet_height) != (CELL * frames, CELL * len(VIEWS)):
        return ["%s: tamanho %dx%d, esperado %dx%d" % (name, width, sheet_height, CELL * frames, CELL * len(VIEWS))]
    colors = set()
    for line in rows:
        for x in range(0, len(line), 4):
            if line[x + 3] not in (0, 255):
                errors.append("%s: pixel semitransparente" % name)
                break
            if line[x + 3]:
                colors.add(line[x:x + 3])
    if len(colors) > 32:
        errors.append("%s: %d cores, o limite é 32. Uma folha com muitas cores veio de imagem reduzida, não de desenho" % (name, len(colors)))
    tallest = 0
    for view, view_name in enumerate(VIEWS):
        cells = [cell_of(rows, view, frame) for frame in range(frames)]
        boxes = [box(cell) for cell in cells]
        if None in boxes:
            errors.append("%s, %s: quadro vazio" % (name, view_name))
            continue
        if any(item[3] != CELL - 1 for item in boxes):
            errors.append("%s, %s: em algum quadro, nada encosta na última linha, e os pés ficariam fora do hexágono" % (name, view_name))
        if len({b"".join(bytes(line) for line in cell) for cell in cells}) < 2:
            errors.append("%s, %s: todos os quadros são iguais" % (name, view_name))
        tallest = max(tallest, max(item[3] - item[2] + 1 for item in boxes))
        print("%s %-5s ocupa x %d-%d, y %d-%d" % (name, view_name, boxes[0][0], boxes[0][1], boxes[0][2], boxes[0][3]))
    print("%s: %dx%d, %d cores, %d pixels de altura" % (name, width, sheet_height, len(colors), tallest))
    if height is not None and abs(tallest - height) > HEIGHT_MARGIN:
        errors.append("%s: %d pixels de altura, e o catálogo pede %d na escala do Domador" % (name, tallest, height))
    return errors


def main():
    folder = Path(sys.argv[1]).resolve()
    # As folhas do mapa ficam em <slug>/explore/ (board-battle/07).
    slug = folder.parent.name if folder.name == "explore" else folder.name
    height = expected_height(slug)
    print("altura pedida pelo catálogo:", "%d pixels" % height if height is not None else "fora do catálogo, sem conferir")
    errors = []
    for name in FRAMES:
        path = folder / (name + ".png")
        if path.exists():
            errors += check(path, name, height)
        else:
            errors.append("falta %s" % path.name)
    for error in errors:
        print("FALHA:", error)
    print("RESULTADO:", "FALHOU" if errors else "PASSOU")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
