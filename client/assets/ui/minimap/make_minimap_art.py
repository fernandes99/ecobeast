"""Desenha a arte do minimapa (.specs/minimap/architecture.md): o anel dourado, a
moldura do mapa grande, a máscara do furo, o pino do Domador e os ícones.

Paleta Ouro e luz de cima à esquerda do guia .specs/town-art/style-guide.md.
Rode desta pasta: python make_minimap_art.py
"""

import math
from pathlib import Path

from PIL import Image

HERE = Path(__file__).parent

GOLD_LIGHT = (255, 240, 144, 255)
GOLD = (248, 200, 56, 255)
GOLD_DARK = (200, 144, 28, 255)
GOLD_LINE = (122, 84, 16, 255)
GEM = (214, 64, 64, 255)
GEM_LIGHT = (255, 150, 140, 255)
GEM_LINE = (106, 26, 26, 255)
WHITE = (255, 255, 255, 255)
CREAM = (246, 236, 214, 255)
HEART = (214, 64, 80, 255)
BROWN_LINE = (90, 58, 32, 255)
INK = (60, 60, 80, 255)

RING = 64
HOLE = 48


def stamp(image, x, y, rows, colors):
    for j, row in enumerate(rows):
        for i, key in enumerate(row):
            if key in colors:
                image.putpixel((x + i, y + j), colors[key])


def ring():
    image = Image.new("RGBA", (RING, RING), (0, 0, 0, 0))
    c = (RING - 1) / 2
    inner = HOLE / 2
    for y in range(RING):
        for x in range(RING):
            dx, dy = x - c, y - c
            d = math.hypot(dx, dy)
            if d < inner or d >= inner + 6.5:
                continue
            band = d - inner
            light = (dx + dy) / max(d, 1)
            if band < 1 or band >= 5.5:
                color = GOLD_LINE
            elif band < 2 or band >= 4.5:
                color = GOLD_DARK
            elif light < -0.55:
                color = GOLD_LIGHT
            elif light > 0.75:
                color = GOLD_DARK
            else:
                color = GOLD
            image.putpixel((x, y), color)
    gold = {"o": GOLD_LINE, "l": GOLD_LIGHT, "g": GOLD, "d": GOLD_DARK}
    diamond = ["..o..", ".olo.", "olgdo", ".odo.", "..o.."]
    for angle in (45, 135, 225, 315):
        a = math.radians(angle)
        x = round(c + math.cos(a) * (inner + 3.2)) - 2
        y = round(c + math.sin(a) * (inner + 3.2)) - 2
        stamp(image, x, y, diamond, gold)
    gem = {"o": GEM_LINE, "r": GEM, "l": GEM_LIGHT, "g": GOLD, "d": GOLD_DARK, "L": GOLD_LINE}
    stamp(image, 28, 0, [
        ".LLLLLL.",
        "LooooooL",
        "LolrrroL",
        "LorrrroL",
        ".LooooL.",
        "..LLLL..",
    ], gem)
    image.save(HERE / "ring.png")


def mask():
    image = Image.new("RGBA", (HOLE, HOLE), (0, 0, 0, 0))
    c = (RING - 1) / 2
    offset = (RING - HOLE) // 2
    for y in range(HOLE):
        for x in range(HOLE):
            if math.hypot(x + offset - c, y + offset - c) < HOLE / 2:
                image.putpixel((x, y), WHITE)
    image.save(HERE / "mask.png")


def frame():
    size = 24
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    for y in range(size):
        for x in range(size):
            inset = min(x, y, size - 1 - x, size - 1 - y)
            if inset >= 5:
                continue
            top_or_left = inset in (x, y) and inset not in (size - 1 - x, size - 1 - y)
            if inset in (0, 4):
                color = GOLD_LINE
            elif inset in (1, 3):
                color = GOLD_DARK
            else:
                color = GOLD_LIGHT if top_or_left else GOLD
            image.putpixel((x, y), color)
    cap = [
        "ooooooooo",
        "ollllllgo",
        "olggggddo",
        "olggggddo",
        "olggggddo",
        "olggggddo",
        "olgggdddo",
        "ogdddddoo",
        "ooooooooo",
    ]
    gold = {"o": GOLD_LINE, "l": GOLD_LIGHT, "g": GOLD, "d": GOLD_DARK}
    for x, y in ((0, 0), (size - 9, 0), (0, size - 9), (size - 9, size - 9)):
        stamp(image, x, y, cap, gold)
    image.save(HERE / "frame.png")


def icons():
    stamp_icon("pin", (5, 6), [
        ".ooo.",
        "orrro",
        "orwro",
        "orrro",
        ".oro.",
        "..o..",
    ], {"o": GEM_LINE, "r": GEM, "w": WHITE})
    stamp_icon("refuge", (7, 7), [
        ".ooooo.",
        "occccco",
        "ocrcrco",
        "ocrrrco",
        "occrcco",
        "occccco",
        ".ooooo.",
    ], {"o": BROWN_LINE, "c": CREAM, "r": HEART})
    stamp_icon("shop", (7, 7), [
        "..ooo..",
        ".ob.bo.",
        "ooooooo",
        "olyyyyo",
        "oyydyyo",
        "oyyyydo",
        ".ooooo.",
    ], {"o": BROWN_LINE, "b": GOLD_LINE, "l": GOLD_LIGHT, "y": GOLD, "d": GOLD_DARK})
    stamp_icon("npc", (7, 7), [
        ".ooooo.",
        "owwwwwo",
        "owiwiwo",
        "owwwwwo",
        ".oowoo.",
        "...oo..",
        ".......",
    ], {"o": INK, "w": WHITE, "i": INK})


def stamp_icon(name, size, rows, colors):
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    stamp(image, 0, 0, rows, colors)
    image.save(HERE / f"{name}.png")


if __name__ == "__main__":
    ring()
    mask()
    frame()
    icons()
