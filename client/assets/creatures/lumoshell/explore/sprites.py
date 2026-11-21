"""Lumoshell: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,8 m, ele tem 16 pixels de altura pela regra do mapa (creature-scale): 14 de desenho e
o contorno marrom por fora. Cabem o casco de placas de cristal âmbar com as arestas escuras
e as frestas claras, a ponta de cristal no topo, o pescoço comprido e a cabeça dourada de
bico curvo e olhar pesado, a barriga creme e as quatro patas grossas. No idle, ele cochila
(a cabeça desce e os olhos fecham) e um brilho corre pelas placas; no walk, as patas andam
em diagonais, devagar, com o casco parado.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build  # noqa: E402

PALETTE = {
    "o": (72, 30, 16),     # contorno
    "W": (252, 240, 184),  # fresta clara
    "A": (244, 178, 60),   # placa na luz
    "M": (220, 122, 46),   # placa âmbar
    "a": (140, 64, 24),    # aresta
    "G": (240, 190, 76),   # pele dourada
    "g": (196, 128, 42),   # pele na sombra
    "k": (120, 64, 26),    # bico e rugas
    "C": (246, 224, 168),  # barriga e garras
    "E": (52, 20, 10),     # olho
}
OUTLINE = {"*": "o"}
HEIGHT = 14
TOP = 31 - HEIGHT

# O casco de lado: o começo e o fim de cada linha.
SIDE_SHELL = [(8, 8), (7, 9), (5, 11), (3, 12), (2, 13), (1, 14), (1, 14), (0, 15), (0, 15)]
FRONT_SHELL = [(8, 8), (7, 9), (5, 11), (3, 13), (2, 14), (1, 15), (1, 15), (0, 16), (0, 16)]
SPARKLES = [(6, 4), (10, 5), (4, 6), (9, 7)]


def plate(x, y):
    if (x + 2 * y) % 5 == 0 or (x - 2 * y) % 6 == 0:
        return "a"
    return "A" if (x // 3 + y // 2) % 2 == 0 or y < 3 else "M"


def blank(width):
    return [["."] * width for _ in range(HEIGHT)]


def put(grid, x, y, char):
    if 0 <= y < HEIGHT and 0 <= x < len(grid[0]) and char != ".":
        grid[y][x] = char


def stamp(grid, rows, left, top):
    for j, row in enumerate(rows):
        for i, char in enumerate(row):
            put(grid, left + i, top + j, char)


def shell(grid, spans, sparkle):
    for y, (start, end) in enumerate(spans):
        for x in range(start, end + 1):
            put(grid, x, y, plate(x, y))
    put(grid, spans[0][0], 0, "W")
    put(grid, spans[1][0] + 1, 1, "W")
    width = len(grid[0])
    for x in range(width):
        put(grid, x, len(spans), "a" if spans[-1][0] <= x <= spans[-1][1] else ".")
    sx, sy = SPARKLES[sparkle]
    put(grid, sx + (width - 20) // 2, sy, "W")


def leg(grid, x, width, color, dx, lift):
    for i in range(width):
        put(grid, x + i, 11, color)
    if lift:
        for i in range(width):
            put(grid, x + dx + i, 12, color)
        return
    for i in range(width):
        put(grid, x + (dx if dx < 0 else 0) + i, 12, color)
        put(grid, x + dx + i, 13, color)
    put(grid, x + dx + width - 1, 13, "C")


SIDE_HEAD = [".GGG.", "GGGEG", "GGGGk", "gGGk."]
FRONT_HEAD = ["a.GGG.a", "aGGGGGa", "aGEGEGa", ".gGkGg.", "..gkg.."]

# Diagonais: a traseira de perto com a dianteira de longe, e o outro par 3 quadros depois.
STEP_DX = (1, 0, -1, -1, 0, 1)
STEP_LIFT = (0, 0, 0, 1, 1, 0)


def side(view, nod, sleepy, sparkle, step):
    grid = blank(20)
    pair_a = step
    pair_b = None if step is None else (step + 3) % 6
    da, la = (0, 0) if step is None else (STEP_DX[pair_a], STEP_LIFT[pair_a])
    db, lb = (0, 0) if step is None else (STEP_DX[pair_b], STEP_LIFT[pair_b])
    leg(grid, 2, 2, "k", db, lb)
    leg(grid, 10, 2, "k", da, la)
    shell(grid, SIDE_SHELL, sparkle)
    for x in range(1, 15):
        put(grid, x, 10, "C" if x > 9 else "g")
    leg(grid, 4, 3, "g", da, la)
    leg(grid, 12, 3, "g", db, lb)
    stamp(grid, [".GG", "GGG", "gGG", "gG."], 13, 6 + nod)
    head = [row.replace("E", "k" if sleepy else "E") for row in SIDE_HEAD]
    if view == "upper":
        head = [row.replace("E", "G") for row in head]
    stamp(grid, head, 15, 4 + nod)
    return ["".join(row) for row in grid]


def facing(view, nod, sleepy, sparkle, step):
    grid = blank(17)
    pair_a = step
    pair_b = None if step is None else (step + 3) % 6
    la = 0 if step is None else STEP_LIFT[pair_a]
    lb = 0 if step is None else STEP_LIFT[pair_b]
    shell(grid, FRONT_SHELL, sparkle)
    for x in range(1, 16):
        put(grid, x, 10, "g")
    leg(grid, 1, 3, "g", 0, la)
    leg(grid, 13, 3, "g", 0, lb)
    if view == "front":
        head = [row.replace("E", "k" if sleepy else "E") for row in FRONT_HEAD]
        stamp(grid, head, 5, 6 + nod)
    else:
        stamp(grid, ["gGg", ".g."], 7, 10)
    return ["".join(row) for row in grid]


def drawing(view, nod, sleepy, sparkle, step):
    if view in ("front", "back"):
        return facing(view, nod, sleepy, sparkle, step), 8
    return side(view, nod, sleepy, sparkle, step), 6


def draw_idle(canvas, view, frame):
    rows, left = drawing(view, (0, 1, 1, 0)[frame], frame in (1, 2), frame, None)
    canvas.stamp(rows, left, TOP)


def draw_walk(canvas, view, frame):
    rows, left = drawing(view, 0, False, frame % 4, frame)
    canvas.stamp(rows, left, TOP)


if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, {"idle": draw_idle, "walk": draw_walk}, outline=OUTLINE)
