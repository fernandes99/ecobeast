"""Desenha os coqueiros da Praia (.specs/beach-life/01-beach-art.md).

Uso: python -I make_beach_life.py [--preview saida.png]   (precisa do Pillow)

Cada tipo é uma linha de decorations/decorations.png (64 e 65), com 4 variantes, no traço do
make_nature.py. Rodar de novo regrava só essas linhas e corta a folha depois delas.
"""

import math
import os
import random
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import make_desert_snow as art  # noqa: E402
import make_nature as nature  # noqa: E402

FIRST_ROW = 64
BX, BY = nature.BASE

PALM = [(14, 42, 30), (26, 76, 40), (46, 110, 48), (80, 146, 60), (126, 182, 82)]
PALM_BARK = [(52, 38, 26), (96, 74, 50), (134, 108, 74), (170, 144, 104)]
COCONUT = [(36, 24, 14), (82, 56, 28), (120, 86, 44), (150, 116, 66)]
COCONUT_GREEN = [(30, 50, 22), (70, 104, 40), (110, 146, 58), (150, 180, 86)]


def outline(cell, body, color):
    for x, y in sorted(body):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            spot = (x + dx, y + dy)
            if spot not in body and spot not in cell.pixels:
                cell.put(spot[0], spot[1], color)


def paint(cell, tones, palette, edge=True):
    """Pinta um mapa ponto→índice de tom com o contorno da primeira cor da paleta."""
    for (x, y), tone in tones.items():
        cell.put(x, y, palette[tone])
    if edge:
        outline(cell, tones, palette[0])


def frond(cell, x0, y0, angle, length, droop, palette):
    """Uma folha de coqueiro: a nervura sai da copa e cai em arco, com os folíolos em pente."""
    tones = {}
    steps = length * 2
    dx, dy = math.cos(angle), math.sin(angle)
    for step in range(steps + 1):
        t = step / steps
        x = round(x0 + dx * length * t)
        y = round(y0 + dy * length * t + droop * t * t)
        tones[(x, y)] = 3
        if t < 0.12:
            continue
        hang = round(3 * (1.0 - abs(t - 0.45) * 1.3)) + (1 if step % 2 else 0)
        for k in range(1, max(1, hang) + 1):
            tones.setdefault((x, y + k), 2 if k < hang else 1)
        if step % 4 == 1 and t < 0.8:
            tones.setdefault((x, y - 1), 4)
    for (x, y), tone in tones.items():
        cell.put(x, y, palette[tone])
    outline(cell, tones, palette[0])


def palm(cell, height, lean, fronds, frond_length, nuts):
    rng = cell.rng
    bark = {}
    top = (BX, BY - height)
    for step in range(height + 1):
        t = step / height
        x = BX + round(lean * t * t)
        y = BY - step
        ring = step % 3 == 0
        for k in range(-1, 2):
            bark[(x + k, y)] = 0 if ring and k != -1 else (3 if k == -1 else (1 if k == 1 else 2))
        if step < 3:
            bark[(x - 2 + (step == 2), y)] = 1
            bark[(x + 2 - (step == 2), y)] = 1
        top = (x, y)
    for (x, y), tone in bark.items():
        cell.put(x, y, PALM_BARK[tone])
    outline(cell, bark, PALM_BARK[0])
    tx, ty = top
    angles = []
    for index in range(fronds):
        base = -math.pi / 2 + (index - (fronds - 1) / 2) * (math.pi * 1.15 / max(fronds - 1, 1))
        angles.append(base + rng.uniform(-0.12, 0.12))
    angles.sort(key=lambda a: -abs(math.cos(a)))
    for a in angles:
        spread = abs(math.cos(a))
        length = round(frond_length * rng.uniform(0.8, 1.0) * (0.55 + 0.45 * spread))
        droop = rng.uniform(5, 9) * (0.4 + spread)
        frond(cell, tx, ty - 1, a, length, droop, PALM)
    cell.put(tx, ty - 1, PALM[4])
    for k in range(nuts):
        nature.blob(cell, [(tx - 2 + k * 2.5, ty + 2.5 + (k % 2), 1.8)], COCONUT if k % 2 == 0 else COCONUT_GREEN)


def coconut_palm(cell, variant):
    rng = cell.rng
    lean = (1 if variant % 2 == 0 else -1) * rng.randint(4, 9)
    palm(cell, rng.randint(36, 42), lean, rng.randint(7, 9), rng.randint(14, 17), rng.randint(2, 3))
    return (8, 2)


def young_palm(cell, variant):
    rng = cell.rng
    lean = rng.choice([-2, -1, 1, 2])
    palm(cell, rng.randint(13, 17), lean, rng.randint(6, 7), rng.randint(11, 13), 0)
    return (7, 2)


KINDS = [coconut_palm, young_palm]


def rows():
    width, height = nature.CELL
    image = Image.new("RGBA", (width * 4, height * len(KINDS)), (0, 0, 0, 0))
    for row, kind in enumerate(KINDS):
        for variant in range(4):
            cell = nature.Cell(random.Random(f"{kind.__name__}:{variant}"))
            shadow = kind(cell, variant)
            image.paste(cell.image(shadow), (variant * width, row * height))
    return image


def preview(file):
    drawn = rows()
    sand = Image.open(art.path("surfaces", "beach.png")).convert("RGBA")
    back = Image.new("RGBA", drawn.size)
    for y in range(0, drawn.height, sand.height):
        for x in range(0, drawn.width, sand.width):
            back.paste(sand, (x, y))
    back.alpha_composite(drawn)
    back.resize((back.width * 3, back.height * 3), Image.NEAREST).save(file)


def main():
    file = art.path("decorations", "decorations.png")
    sheet = Image.open(file).convert("RGBA")
    sheet = sheet.crop((0, 0, sheet.width, min(sheet.height, FIRST_ROW * nature.CELL[1])))
    art.put_rows(sheet, rows(), nature.CELL[1], FIRST_ROW).save(file)


if __name__ == "__main__":
    if "--preview" in sys.argv:
        preview(sys.argv[sys.argv.index("--preview") + 1])
    else:
        main()
    print("ok")
