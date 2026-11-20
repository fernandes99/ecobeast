"""Gera a arte provisória da Praia (.specs/coast-rivers/01-sea-and-beach.md).

Uso: python -I make_beach.py   (precisa do Pillow; roda de dentro de assets/terrain)

- surfaces/beach.png, a partir de surfaces/hill.png, com pontinhos de concha;
- a linha 8 de transitions/transitions.png e a linha 5 de transitions/drips.png, a partir das da Colina;
- as linhas 47 a 50 de decorations/decorations.png: conchas, estrela-do-mar, tronco à deriva e pedra de praia;
Rodar de novo regrava só essas linhas.
"""

import os
import random
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import make_desert_snow as art  # noqa: E402
import make_nature as nature  # noqa: E402

BEACH = [(160, 136, 104), (204, 184, 148), (228, 214, 182), (242, 234, 210), (252, 249, 236)]
SHELL_DOTS = [(246, 214, 206), (255, 250, 240), (214, 170, 150)]
SHELLS = [[(150, 96, 92), (232, 168, 160), (252, 222, 214)], [(140, 118, 92), (226, 206, 170), (250, 240, 220)]]
STARFISH = [[(150, 60, 40), (226, 108, 70), (250, 160, 110)], [(130, 50, 80), (204, 92, 130), (240, 150, 176)]]
DRIFTWOOD = [(104, 92, 78), (160, 148, 128), (196, 186, 166), (226, 220, 204)]
WET_ROCK = [(44, 42, 40), (74, 72, 68), (98, 96, 90), (126, 122, 114), (158, 154, 144), (190, 186, 176)]
BARNACLE = [(214, 208, 196), (240, 236, 226)]
FIRST_DECORATION_ROW = 47


def surface():
    image = art.recolor(Image.open(art.path("surfaces", "hill.png")), BEACH).convert("RGB")
    pixels = image.load()
    rng = random.Random(47)
    for _ in range(image.width * image.height // 900):
        x, y = rng.randrange(image.width), rng.randrange(image.height)
        color = SHELL_DOTS[rng.randrange(len(SHELL_DOTS))]
        pixels[x, y] = color
        if rng.random() < 0.4:
            pixels[(x + 1) % image.width, y] = SHELL_DOTS[2]
    image.save(art.path("surfaces", "beach.png"))


def transitions():
    file = art.path("transitions", "transitions.png")
    sheet = Image.open(file).convert("RGBA")
    height = art.TRANSITION_CELL[1] * art.TRANSITION_VARIANTS
    hill = art.sheet_rows(sheet, height, 3, 1)
    art.put_rows(sheet, art.recolor(hill, BEACH), height, 8).save(file)
    file = art.path("transitions", "drips.png")
    sheet = Image.open(file).convert("RGBA")
    height = art.DRIP_CELL_HEIGHT * 2
    hill = art.sheet_rows(sheet, height, 2, 1)
    art.put_rows(sheet, art.recolor(hill, BEACH, skip_shadow=False), height, 5).save(file)


def shells(cell, variant):
    rng = cell.rng
    fan = [(-1, 0), (0, 0), (1, 0), (-2, -1), (-1, -1), (0, -1), (1, -1), (2, -1), (-2, -2), (-1, -2), (0, -2), (1, -2), (2, -2), (-1, -3), (0, -3), (1, -3)]
    spiral = [(0, 0), (1, 0), (2, 0), (-1, -1), (0, -1), (1, -1), (2, -1), (0, -2), (1, -2)]
    spots = []
    for index in range(rng.randint(2, 3)):
        for _ in range(8):
            x = nature.BASE[0] + rng.randint(-8, 8)
            y = nature.BASE[1] - rng.randint(0, 2)
            if all(abs(x - ox) > 5 or abs(y - oy) > 4 for ox, oy in spots):
                break
        spots.append((x, y))
        tones = SHELLS[(variant + index) % 2]
        body = fan if (variant + index) % 3 != 0 else spiral
        shape = {(x + dx, y + dy) for dx, dy in body}
        for px, py in shape:
            edge = any((px + ex, py + ey) not in shape for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            ridge = body is fan and (px - x) % 2 == 0
            cell.put(px, py, tones[0] if edge else (tones[1] if ridge else tones[2]))
    return (9, 1)


def starfish(cell, variant):
    tones = STARFISH[variant % 2]
    x, y = nature.BASE[0] + cell.rng.randint(-3, 3), nature.BASE[1] - 2
    arms = [(0, -4), (4, -1), (3, 3), (-3, 3), (-4, -1)]
    for ax, ay in arms:
        nature.line(cell, x, y, x + ax, y + ay, tones[1])
        cell.put(x + ax, y + ay, tones[0])
    for dx, dy in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)):
        cell.put(x + dx, y + dy, tones[2] if (dx, dy) == (0, 0) else tones[1])
    return (5, 1)


def driftwood(cell, variant):
    nature.branch(cell, DRIFTWOOD)
    return (11, 2)


def beach_rock(cell, variant):
    width = cell.rng.randint(14, 19)
    shape = nature.facet_rock(cell, WET_ROCK, width, cell.rng.randint(7, 10))
    inside = [spot for spot in sorted(shape) if cell.pixels[spot] != WET_ROCK[0]]
    for _ in range(cell.rng.randint(4, 7)):
        x, y = cell.rng.choice(inside)
        cell.put(x, y, BARNACLE[cell.rng.randrange(2)])
    return (width // 2, 2)


KINDS = [shells, starfish, driftwood, beach_rock]


def decorations():
    file = art.path("decorations", "decorations.png")
    sheet = Image.open(file).convert("RGBA")
    height = nature.CELL[1]
    rows = Image.new("RGBA", (sheet.width, height * len(KINDS)), (0, 0, 0, 0))
    for row, kind in enumerate(KINDS):
        for variant in range(4):
            cell = nature.Cell(random.Random(f"{kind.__name__}:{variant}"))
            shadow = kind(cell, variant)
            rows.paste(cell.image(shadow), (variant * nature.CELL[0], row * height))
    art.put_rows(sheet, rows, height, FIRST_DECORATION_ROW).save(file)


if __name__ == "__main__":
    surface()
    transitions()
    decorations()
    print("ok")
