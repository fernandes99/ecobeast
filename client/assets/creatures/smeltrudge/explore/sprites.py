"""Smeltrudge: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,90 m, ele tem 17 pixels de altura pela regra do mapa (creature-scale): 15 de desenho e
o contorno marrom-escuro por fora. A concha virou fornalha: a chaminé com a fumaça, a
portinha de grade acesa na lateral, os rebites e o espinho de ferro; na frente, a cara
emburrada, de sobrancelha baixa e olho amarelo, e as antenas de ponta acesa. Sem patas,
ele anda esticando o pé: a cabeça vai à frente e a concha chega um quadro depois.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, swayed  # noqa: E402

PALETTE = {
    "o": (44, 28, 26),     # contorno
    "m": (70, 60, 64),     # ferro na sombra
    "M": (108, 98, 100),   # ferro
    "I": (156, 146, 144),  # ferro na luz
    "R": (198, 186, 178),  # rebite
    "F": (246, 126, 28),   # brasa
    "Y": (255, 214, 90),   # brasa acesa
    "B": (176, 150, 128),  # corpo
    "b": (128, 104, 90),   # corpo na sombra
    "H": (214, 192, 166),  # corpo na luz
    "k": (36, 20, 16),     # sobrancelha e pupila
    "E": (255, 190, 40),   # olho
    "S": (196, 182, 174),  # fumaça
    "s": (150, 136, 130),  # fumaça na sombra
}
OUTLINE = {"*": "o", "S": "s", "s": "s"}
BOTTOM = 30
HEIGHT = 15


class Grid:
    def __init__(self, width, height):
        self.width, self.height = width, height
        self.px = {}

    def put(self, x, y, key):
        if 0 <= x < self.width and 0 <= y < self.height:
            self.px[(x, y)] = key

    def ellipse(self, cx, cy, rx, ry, rim, light, base, dark):
        """Elipse sombreada: luz no alto à esquerda, sombra embaixo à direita e a borda escura."""
        for y in range(self.height):
            for x in range(self.width):
                d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
                if d > 1:
                    continue
                if d > 0.72:
                    key = rim
                elif (x - cx) + (y - cy) < -rx * 0.55:
                    key = light
                elif (x - cx) + (y - cy) > rx * 0.45:
                    key = dark
                else:
                    key = base
                self.put(x, y, key)

    def rect(self, x0, y0, x1, y1, key):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.put(x, y, key)

    def stamp(self, rows, left, top):
        for j, row in enumerate(rows):
            for i, key in enumerate(row):
                if key != ".":
                    self.put(left + i, top + j, key)

    def rows(self):
        return ["".join(self.px.get((x, y), ".") for x in range(self.width)) for y in range(self.height)]


DOOR = [
    "mmmm",
    "mFFm",
    "YFYF",
    "YFYF",
    "mmmm",
]
CHIMNEY = [
    "mYFm",
    "IIMm",
    "IMMm",
    "IMmm",
]
SPIKE = [
    ".m",
    "Mm",
]
HEAD_SIDE = [
    "..bBBBb.",
    ".bBHHHBb",
    "bBkkHHBB",
    "bBBkkkkB",
    "bBBEkEkB",
    "bBBHHHBB",
    "bBBBBBBb",
    "bbBBBBbb",
]
ANTENNA = ["YY.", "YY.", ".b.", "..b", "..b"]
HEAD_FRONT = [
    "..bBBBBb..",
    ".bHHHHHHb.",
    "bkkHHHHkkb",
    "bBkkHHkkBb",
    "bBEkBBkEBb",
    "bBBBHHBBBb",
    "bbBBBBBBbb",
    ".bbBBBBbb.",
]


def side_view(eyes=True):
    g = Grid(21, HEIGHT)
    g.ellipse(6.5, 8.6, 6.6, 5.6, "m", "I", "M", "m")
    for x, y in ((2, 5), (6, 3), (11, 5), (12, 10), (1, 10), (6, 13)):
        g.put(x, y, "R")
    g.stamp(DOOR, 5, 7)
    g.stamp(CHIMNEY, 4, 2)
    g.stamp(SPIKE, 0, 4)
    head = HEAD_SIDE if eyes else [r.replace("k", "B").replace("E", "B") for r in HEAD_SIDE]
    g.stamp(head, 12, 6)
    g.stamp(ANTENNA, 13, 1)
    g.stamp(ANTENNA, 17, 2)
    g.rect(0, 14, 20, 14, "b")
    g.rect(1, 13, 19, 13, "B")
    g.rect(12, 13, 19, 13, "B")
    return g.rows()


def front_view():
    g = Grid(18, HEIGHT)
    g.ellipse(8.5, 7.5, 8.4, 5.4, "m", "I", "M", "m")
    for x, y in ((2, 7), (15, 7), (5, 3), (12, 3)):
        g.put(x, y, "R")
    g.stamp(CHIMNEY, 7, 1)
    g.stamp(SPIKE, 1, 3)
    g.stamp(HEAD_FRONT, 4, 6)
    g.stamp(ANTENNA, 3, 2)
    g.stamp([r[::-1] for r in ANTENNA], 13, 2)
    g.rect(1, 14, 16, 14, "b")
    g.rect(3, 13, 14, 13, "B")
    return g.rows()


def back_view():
    g = Grid(18, HEIGHT)
    g.ellipse(8.5, 8.0, 8.4, 6.0, "m", "I", "M", "m")
    g.ellipse(8.5, 8.4, 4.2, 3.2, "F", "Y", "m", "M")
    g.ellipse(8.5, 8.4, 2.0, 1.4, "Y", "M", "m", "m")
    for x, y in ((2, 8), (15, 8), (5, 3), (12, 3), (8, 13)):
        g.put(x, y, "R")
    g.stamp(CHIMNEY, 7, 1)
    g.stamp(SPIKE, 1, 3)
    g.stamp(["YY", "YY"], 1, 2)
    g.stamp(["YY", "YY"], 15, 2)
    g.rect(1, 14, 16, 14, "b")
    return g.rows()


SIDE = side_view()
VIEW_ART = {
    "front": (front_view(), None, 8),
    "lower": (SIDE, 12, 4),
    "side": (SIDE, 12, 4),
    "upper": (side_view(eyes=False), 12, 4),
    "back": (back_view(), None, 8),
}
SMOKE = swayed([".SS.", "SsSs"], (0, 1, 0, -1))
SMOKE_WALK = (0, 0, 1, 1, 0, -1)

IDLE_TIPS = (0, 1, 0, -1)
WALK_HEAD = (0, 1, 1, 1, 0, 0)
WALK_SHELL = (0, 0, 0, 1, 1, 0)
WALK_TIPS = (0, 0, 1, 0, 0, -1)


def stretched_side(art, split, head_dx, shell_dx):
    rows = []
    for row in art:
        back, front = row[:split], row[split:]
        line = ["."] * (len(row) + 2)
        for i, mark in enumerate(back):
            if mark != ".":
                line[i + shell_dx] = mark
        for i, mark in enumerate(front):
            if mark != ".":
                line[split + head_dx + i] = mark
        if back[-1] != "." and front[0] != ".":
            for x in range(split + shell_dx, split + head_dx):
                line[x] = front[0]
        rows.append("".join(line))
    return rows


def glowing(art, lit):
    return [row.replace("F", "#").replace("Y", "F").replace("#", "Y") for row in art] if lit else art


def swayed_tips(art, dx):
    """As pontas acesas das antenas (as duas primeiras linhas, fora da chaminé) balançam."""
    if dx == 0:
        return art
    out = list(art)
    for y in (1, 2):
        row = out[y]
        tips = "".join(m if m == "Y" and i > 9 else "." for i, m in enumerate(row))
        rest = "".join("." if m == "Y" and i > 9 else m for i, m in enumerate(row))
        moved = ("." * dx + tips[:-dx]) if dx > 0 else (tips[-dx:] + "." * -dx)
        out[y] = "".join(t if t != "." else r for t, r in zip(moved, rest))
    return out


def draw(canvas, view, frame, walking):
    art, split, smoke_x = VIEW_ART[view]
    shell_dx = 0
    if walking and split is not None:
        shell_dx = WALK_SHELL[frame]
        art = stretched_side(art, split, WALK_HEAD[frame], shell_dx)
    tips = (WALK_TIPS if walking else IDLE_TIPS)[frame]
    if split is not None:
        art = swayed_tips(art, tips)
    art = glowing(art, frame % 2 == 1)
    width = len(art[0])
    left = 16 - width // 2
    top = BOTTOM - len(art) + 1
    canvas.stamp(art, left, top)
    smoke = SMOKE[(SMOKE_WALK[frame] % 4) if walking else frame]
    canvas.stamp(smoke, left + smoke_x - 1 + shell_dx - (0 if split is not None else 1), top)


if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        {"idle": lambda c, v, f: draw(c, v, f, False), "walk": lambda c, v, f: draw(c, v, f, True)},
        outline=OUTLINE,
    )
