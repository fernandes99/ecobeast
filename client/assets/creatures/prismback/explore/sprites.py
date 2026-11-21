"""Prismback: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,3 m, ele tem 23 pixels de altura pela regra do mapa (creature-scale): 21 de desenho e
o contorno marrom por fora. Cabem o casco de prismas de cristal furta-cor (âmbar, lilás,
azul-claro e rosa) com a ponta alta e as pontas menores, a cabeça dourada de pálpebras
caídas, a barbicha creme, a cauda pontuda e as quatro patas grossas com as garras. No idle,
ele cochila (a cabeça desce e os olhos fecham) e um brilho corre pelos prismas; no walk, as
patas andam em diagonais, devagar, com o casco parado.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build  # noqa: E402

PALETTE = {
    "o": (72, 30, 16),     # contorno
    "W": (252, 246, 220),  # prisma claro
    "L": (206, 176, 232),  # prisma lilás
    "B": (168, 214, 240),  # prisma azul-claro
    "P": (244, 186, 196),  # prisma rosa
    "A": (244, 190, 84),   # prisma âmbar na luz
    "M": (214, 128, 52),   # prisma âmbar
    "a": (132, 70, 40),    # aresta
    "G": (226, 168, 64),   # pele dourada
    "g": (178, 112, 40),   # pele na sombra
    "k": (110, 60, 28),    # pata de longe, rugas e bico
    "C": (244, 228, 190),  # barbicha e garras
    "E": (52, 20, 10),     # olho
}
OUTLINE = {"*": "o"}
HEIGHT = 21
TOP = 31 - HEIGHT
RIM = 15

SIDE_SHELL = [
    [(13, 13)], [(12, 14)], [(12, 14)], [(7, 7), (11, 15), (17, 17)], [(6, 8), (10, 18)],
    [(5, 19)], [(4, 19)], [(3, 20)], [(2, 20)], [(2, 21)], [(1, 21)], [(1, 21)], [(1, 22)],
    [(1, 22)], [(1, 22)],
]
FRONT_SHELL = [
    [(11, 11)], [(10, 12)], [(10, 12)], [(5, 5), (9, 13), (17, 17)], [(4, 6), (8, 14), (16, 18)],
    [(3, 19)], [(2, 20)], [(2, 20)], [(1, 21)], [(1, 21)], [(1, 21)], [(0, 22)], [(0, 22)],
    [(0, 22)], [(0, 22)],
]
PRISMS = "AWLMBAPLAB"
LIGHT = {"A": "A", "M": "A", "W": "W", "L": "W", "B": "W", "P": "W"}
DARK = {"A": "M", "M": "M", "W": "L", "L": "L", "B": "B", "P": "P"}
SPARKLES = [(13, 1), (8, 6), (15, 8), (5, 10)]


def prism(x, y):
    if (x + y) % 7 == 0 or (x - y) % 8 == 0:
        return "a"
    if y >= 13:
        return "A" if ((x - y) // 8) % 2 else "M"
    base = PRISMS[((x + y) // 7 * 3 + (x - y + 32) // 8) % len(PRISMS)]
    return LIGHT[base] if (x - y) % 8 < 4 else DARK[base]


def blank(width):
    return [["."] * width for _ in range(HEIGHT)]


def put(grid, x, y, char):
    if 0 <= y < HEIGHT and 0 <= x < len(grid[0]) and char != ".":
        grid[y][x] = char


def stamp(grid, rows, left, top):
    for j, row in enumerate(rows):
        for i, char in enumerate(row):
            put(grid, left + i, top + j, char)


def shell(grid, spans, sparkle, shift):
    for y, row in enumerate(spans):
        for start, end in row:
            for x in range(start, end + 1):
                put(grid, x, y, prism(x - shift, y))
    for start, end in spans[0] + spans[1]:
        put(grid, start, 0 if start == spans[0][0][0] else 1, "W")
    for start, end in spans[-1]:
        for x in range(start, end + 1):
            put(grid, x, RIM, "a")
    sx, sy = SPARKLES[sparkle]
    put(grid, sx - shift, sy, "W")


def leg(grid, x, width, color, dx, lift):
    for y in range(17, 19):
        for i in range(width):
            put(grid, x + i, y, color)
    foot = 19 if lift else 20
    if not lift:
        for i in range(width):
            put(grid, x + (dx if dx < 0 else 0) + i, 19, color)
    for i in range(width):
        put(grid, x + dx + i, foot, color)
    put(grid, x + dx + width - 1, foot, "C")
    put(grid, x + dx + width - 3, foot, "C")


SIDE_HEAD = [".GGG.", "GGGGG", "GGkkG", "GGGEG", "CGGGk", "CCGk.", "CCC..", ".CC..", ".C..."]
FRONT_HEAD = ["..GGG..", ".GGGGG.", "kGkGkGk", "kGEGEGk", ".GGkGG.", ".CCCCC.", "..CCC..", "...C..."]

STEP_DX = (1, 0, -1, -1, 0, 1)
STEP_LIFT = (0, 0, 0, 1, 1, 0)


def steps(step):
    if step is None:
        return (0, 0), (0, 0)
    other = (step + 3) % 6
    return (STEP_DX[step], STEP_LIFT[step]), (STEP_DX[other], STEP_LIFT[other])


def eyes(rows, view, sleepy):
    if view == "upper":
        return [row.replace("E", "G") for row in rows]
    return [row.replace("E", "k") for row in rows] if sleepy else rows


def side(view, nod, sleepy, sparkle, step):
    grid = blank(25)
    (da, la), (db, lb) = steps(step)
    leg(grid, 3, 3, "k", db, lb)
    leg(grid, 12, 3, "k", da, la)
    shell(grid, SIDE_SHELL, sparkle, 0)
    for x, y in ((1, 7), (0, 10), (0, 13)):
        put(grid, x, y, "L")
    put(grid, 0, 15, "g")
    put(grid, 0, 16, "k")
    for x in range(2, 21):
        put(grid, x, 16, "C" if x > 14 else "g")
    leg(grid, 5, 4, "g", da, la)
    leg(grid, 15, 4, "g", db, lb)
    stamp(grid, [".GG", "GGG", "gGG", "gG."], 18, 12 + nod)
    stamp(grid, eyes(SIDE_HEAD, view, sleepy), 20, 10 + nod)
    return ["".join(row) for row in grid]


def facing(view, nod, sleepy, sparkle, step):
    grid = blank(23)
    (da, la), (db, lb) = steps(step)
    leg(grid, 6, 3, "k", 0, lb)
    leg(grid, 14, 3, "k", 0, la)
    shell(grid, FRONT_SHELL, sparkle, 2)
    for x in range(1, 22):
        put(grid, x, 16, "g")
    leg(grid, 1, 4, "g", 0, la)
    leg(grid, 18, 4, "g", 0, lb)
    if view == "front":
        stamp(grid, eyes(FRONT_HEAD, view, sleepy), 8, 11 + nod)
    else:
        put(grid, 11, 16, "G")
        put(grid, 11, 17, "k")
    return ["".join(row) for row in grid]


def drawing(view, nod, sleepy, sparkle, step):
    if view in ("front", "back"):
        return facing(view, nod, sleepy, sparkle, step), 5
    return side(view, nod, sleepy, sparkle, step), 3


def draw_idle(canvas, view, frame):
    rows, left = drawing(view, (0, 1, 1, 0)[frame], frame in (1, 2), frame, None)
    canvas.stamp(rows, left, TOP)


def draw_walk(canvas, view, frame):
    rows, left = drawing(view, 0, False, frame % 4, frame)
    canvas.stamp(rows, left, TOP)


if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, {"idle": draw_idle, "walk": draw_walk}, outline=OUTLINE)
