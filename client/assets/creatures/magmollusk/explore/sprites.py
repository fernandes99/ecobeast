"""Magmollusk: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,60 m, ele tem 28 pixels de altura pela regra do mapa (creature-scale): 26 de desenho e
o contorno escuro por fora. É um caracol velho e enorme: o corpo de pedra escura com frestas
de lava, a barbicha creme, a sobrancelha pesada e o olho amarelo; a concha é uma fornalha de
placas rebitadas e espinhos, com a chaminé soltando fogo e fumaça escura e o metal derretido
escorrendo da boca da fornalha até a poça no chão. Sem patas, ele anda esticando o pé: a
cabeça vai à frente e a concha chega um quadro depois.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, swayed  # noqa: E402

PALETTE = {
    "o": (36, 22, 20),     # contorno
    "m": (62, 54, 58),     # ferro na sombra
    "M": (100, 90, 92),    # ferro
    "I": (148, 138, 136),  # ferro na luz
    "R": (190, 178, 170),  # rebite
    "F": (246, 120, 24),   # lava
    "Y": (255, 210, 80),   # lava acesa
    "r": (186, 58, 20),    # lava escura
    "B": (96, 78, 70),     # pedra do corpo
    "b": (62, 48, 44),     # pedra na sombra
    "H": (136, 114, 100),  # pedra na luz
    "W": (234, 214, 178),  # barbicha
    "w": (188, 164, 130),  # barbicha na sombra
    "k": (30, 16, 12),     # sobrancelha e pupila
    "E": (255, 186, 36),   # olho
    "S": (104, 88, 88),    # fumaça
    "s": (70, 58, 58),     # fumaça na sombra
}
OUTLINE = {"*": "o", "S": "s", "s": "s"}
BOTTOM = 30
HEIGHT = 26


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
                if d > 0.78:
                    key = rim
                elif (x - cx) + (y - cy) < -rx * 0.5:
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


CHIMNEY = [
    "MmmmM",
    "IFMFm",
    "IYMYm",
    "IMMmm",
]
DOOR = [
    ".mmmm.",
    "mFYYFm",
    "mYmYmm",
    "mYmYmm",
    "mmmmmm",
    ".FYF..",
]
SPIKE = [
    ".I.",
    ".Im",
    "IMm",
]
HEAD_SIDE = [
    "...bbBBb...",
    "..bBHHHHb..",
    ".bBHHHHHBb.",
    "bBBHHHHHHBb",
    "bBFBBkkkBBB",
    "bBrBBkEEkkB",
    "bBBBBBEkBBB",
    "bBFBBBBBBBb",
    "bBrBBBWWWBb",
    "bBBBBWWWWWb",
    "bBBBWWwWWWb",
    ".bBBWwWWwW.",
    "..bBWWwWW..",
    "...bwW.w...",
]
HEAD_FRONT = [
    "..bbBBBBbb..",
    ".bBHHHHHHBb.",
    "bBHHHHHHHHBb",
    "bkkkHHHHkkkb",
    "bBkkkHHkkkBb",
    "bBEEkBBkEEBb",
    "bBEkBBBBkEBb",
    "bFBBBBBBBBFb",
    "brBBWWWWBBrb",
    "bBBWWWWWWBBb",
    ".bBWWwwWWBb.",
    "..bWwWWwWb..",
    "...wW..Ww...",
]
ANTENNA = ["YY..", "YY..", ".b..", ".b..", "..b.", "..b.", "..b."]


def base_rock(g, x0, x1, y):
    for x in range(x0, x1 + 1):
        g.put(x, y, "b")
        g.put(x, y - 1, "B" if x % 5 else "F")


def side_view(eyes=True):
    g = Grid(26, HEIGHT)
    g.ellipse(9.5, 16.0, 9.6, 8.2, "m", "I", "M", "m")
    for x in range(3, 17):
        g.put(x, 15, "F" if x % 4 else "m")
    for y in (10, 11, 12, 13, 14):
        g.put(11, y, "m")
    for y in (16, 17, 18, 19, 20, 21):
        g.put(8, y, "m")
    for x, y in ((4, 11), (9, 9), (14, 10), (17, 14), (13, 19), (5, 21), (11, 23)):
        g.put(x, y, "R")
    g.stamp(SPIKE, 2, 7)
    g.stamp(SPIKE, 13, 6)
    g.stamp(SPIKE, 17, 9)
    g.stamp(CHIMNEY, 6, 5)
    g.stamp(DOOR, 1, 13)
    head = HEAD_SIDE if eyes else [r.replace("k", "B").replace("E", "B") for r in HEAD_SIDE]
    g.stamp(head, 14, 10)
    g.stamp(ANTENNA, 15, 4)
    g.stamp(ANTENNA, 19, 5)
    base_rock(g, 4, 25, 25)
    return g.rows()


def front_view():
    g = Grid(26, HEIGHT)
    g.ellipse(12.5, 14.0, 12.4, 8.6, "m", "I", "M", "m")
    for x, y in ((3, 12), (22, 12), (7, 7), (18, 7), (2, 18), (23, 18)):
        g.put(x, y, "R")
    g.stamp(SPIKE, 3, 5)
    g.stamp(SPIKE, 19, 5)
    g.stamp(CHIMNEY, 10, 4)
    for x in range(2, 24):
        g.put(x, 13, "F" if x % 4 else "m")
    g.stamp(HEAD_FRONT, 7, 12)
    g.stamp(ANTENNA, 6, 6)
    g.stamp([r[::-1] for r in ANTENNA], 16, 6)
    base_rock(g, 2, 23, 25)
    return g.rows()


def back_view():
    g = Grid(26, HEIGHT)
    g.ellipse(12.5, 14.5, 12.4, 9.0, "m", "I", "M", "m")
    for x, y in ((3, 12), (22, 12), (7, 7), (18, 7), (3, 19), (22, 19)):
        g.put(x, y, "R")
    g.stamp(SPIKE, 3, 5)
    g.stamp(SPIKE, 19, 5)
    g.stamp(CHIMNEY, 10, 4)
    for x in range(2, 24):
        g.put(x, 12, "F" if x % 4 else "m")
    g.stamp(DOOR, 10, 13)
    g.stamp(["YY", "YY"], 2, 6)
    g.stamp(["YY", "YY"], 22, 6)
    base_rock(g, 2, 23, 25)
    return g.rows()


SIDE = side_view()
# (desenho, coluna da emenda concha-cabeça, coluna da chaminé, coluna da lava que escorre)
VIEW_ART = {
    "front": (front_view(), None, 12, None),
    "lower": (SIDE, 14, 8, 2),
    "side": (SIDE, 14, 8, 2),
    "upper": (side_view(eyes=False), 14, 8, 2),
    "back": (back_view(), None, 12, 11),
}
SMOKE = swayed(["..SS..", ".SSsSS", "SSsSSs", ".sSSs.", "..FYF."], (0, 1, 0, -1))
POUR = [["F", "Y", "F", "r"], ["Y", "F", "r", "F"], ["F", "r", "F", "Y"], ["r", "F", "Y", "F"]]
POOL = ["rFYFFr", "FFrFYF"]

IDLE_TIPS = (0, 1, 0, -1)
WALK_HEAD = (0, 1, 1, 1, 0, 0)
WALK_SHELL = (0, 0, 0, 1, 1, 0)
WALK_TIPS = (0, 0, 1, 0, 0, -1)
WALK_FLOW = (0, 1, 2, 3, 0, 1)


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


def swayed_tips(art, dx, first_col):
    """As pontas acesas das antenas balançam `dx` colunas."""
    if dx == 0:
        return art
    out = list(art)
    for y in range(2, 7):
        row = out[y]
        tips = "".join(m if m == "Y" and i >= first_col else "." for i, m in enumerate(row))
        rest = "".join("." if m == "Y" and i >= first_col else m for i, m in enumerate(row))
        moved = ("." * dx + tips[:-dx]) if dx > 0 else (tips[-dx:] + "." * -dx)
        out[y] = "".join(t if t != "." else r for t, r in zip(moved, rest))
    return out


def draw(canvas, view, frame, walking):
    art, split, chimney_x, pour_x = VIEW_ART[view]
    shell_dx = 0
    if walking and split is not None:
        shell_dx = WALK_SHELL[frame]
        art = stretched_side(art, split, WALK_HEAD[frame], shell_dx)
    tips = (WALK_TIPS if walking else IDLE_TIPS)[frame]
    if split is not None:
        art = swayed_tips(art, tips, split)
    flow = WALK_FLOW[frame] if walking else frame
    width = len(art[0])
    left = 16 - width // 2
    top = BOTTOM - len(art) + 1
    canvas.stamp(art, left, top)
    if pour_x is not None:
        x = left + pour_x + shell_dx
        for y in range(19, HEIGHT - 1):
            canvas.stamp([POUR[flow][y % 4] * 2], x, top + y)
        canvas.stamp(POOL, x - 2, top + HEIGHT - 2)
    smoke = SMOKE[frame % 4]
    canvas.stamp(smoke, left + chimney_x - 3 + shell_dx, top)


if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        {"idle": lambda c, v, f: draw(c, v, f, False), "walk": lambda c, v, f: draw(c, v, f, True)},
        outline=OUTLINE,
    )
