"""Desenha os 24 tipos novos de decoração (.specs/nature-variety/01-nature-art.md).

Uso: python -I make_nature.py   (precisa do Pillow; roda de dentro de assets/terrain)

Cada tipo é uma linha de decorations/decorations.png (23 a 46), com 4 variantes, no traço
das decorações de hoje: formas de círculos com contorno escuro de 1 px, luz de cima à
esquerda com pontilhado e a mesma sombra no pé. Rodar de novo regrava só essas linhas.
"""

import math
import os
import random

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
CELL = (48, 64)
BASE = (24, 60)
FIRST_ROW = 23
SHADOW = (12, 26, 18, 72)
LIGHT = (-0.55, -0.65, 0.52)
BAYER = [[0.0, 0.5], [0.75, 0.25]]

BIRCH_LEAVES = [(24, 64, 30), (44, 104, 44), (70, 140, 56), (110, 176, 70), (160, 206, 96), (204, 230, 134)]
OAK_LEAVES = [(14, 46, 26), (26, 74, 38), (40, 100, 46), (62, 128, 54), (92, 156, 66), (132, 186, 84)]
FIR_LEAVES = [(8, 30, 34), (14, 50, 54), (22, 72, 72), (34, 96, 90), (52, 122, 108), (82, 150, 128)]
BERRY_LEAVES = [(10, 40, 32), (18, 66, 48), (30, 92, 62), (48, 118, 76), (78, 146, 94)]
WINTER_LEAVES = [(30, 50, 58), (52, 84, 88), (82, 116, 116), (124, 156, 154), (176, 202, 206)]
BARK = [(46, 32, 22), (82, 58, 38), (117, 85, 58), (152, 116, 80)]
DRY_BARK = [(58, 50, 40), (96, 84, 68), (132, 118, 96), (170, 156, 130)]
BLEACHED = [(112, 98, 80), (176, 164, 142), (214, 204, 184), (238, 232, 216)]
FROZEN = [(40, 34, 36), (74, 62, 58), (104, 92, 88), (140, 150, 166)]
BIRCH_BARK = [(40, 40, 36), (176, 172, 160), (222, 220, 210), (246, 244, 236)]
WOOD_END = [(150, 110, 70), (200, 166, 112), (226, 196, 140)]
STONE = [(44, 52, 60), (74, 86, 97), (95, 108, 120), (120, 133, 143), (151, 163, 173), (188, 198, 205), (223, 230, 234)]
ROCK = [(55, 52, 46), (93, 88, 79), (116, 112, 101), (142, 137, 124), (171, 166, 151), (203, 199, 184)]
ICE = [(52, 92, 132), (96, 152, 196), (150, 204, 232), (200, 236, 250), (246, 253, 255)]
SNOW = [(150, 170, 200), (196, 212, 236), (236, 244, 252)]
TUMBLE = [(96, 70, 42), (140, 108, 66), (182, 148, 96), (214, 186, 132)]
GRASS = [(40, 104, 42), (62, 138, 54), (100, 178, 70), (152, 214, 96)]
DRY_GRASS = [(96, 104, 48), (132, 140, 62), (170, 172, 84), (206, 202, 116)]
DUNE_GRASS = [(110, 116, 66), (150, 152, 88), (188, 186, 116), (222, 216, 152)]
STEM = [(44, 112, 48), (63, 140, 56)]
LICHEN = [(206, 176, 70), (170, 192, 92), (230, 210, 120)]


def path(*parts):
    return os.path.join(HERE, *parts)


class Cell:
    """Uma célula de 48×64 com os pixels de cor e um sorteio próprio."""

    def __init__(self, rng):
        self.rng = rng
        self.pixels = {}

    def put(self, x, y, color):
        if 0 <= x < CELL[0] and 0 <= y < CELL[1]:
            self.pixels[(x, y)] = color

    def image(self, shadow):
        cell = Image.new("RGBA", CELL, (0, 0, 0, 0))
        data = cell.load()
        if shadow:
            rx, ry = shadow
            for y in range(BASE[1] - ry, BASE[1] + ry + 1):
                for x in range(BASE[0] - rx, BASE[0] + rx + 1):
                    if ((x - BASE[0]) / (rx + 0.5)) ** 2 + ((y - BASE[1]) / (ry + 0.5)) ** 2 <= 1.0:
                        data[x, y] = SHADOW
        for (x, y), color in self.pixels.items():
            data[x, y] = tuple(color) + (255,)
        return cell


def shade_index(nx, ny, levels, x, y, bias=0.0):
    nz = math.sqrt(max(0.0, 1.0 - nx * nx - ny * ny))
    length = math.sqrt(sum(k * k for k in LIGHT))
    light = (nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2]) / length
    value = min(max((light + 0.35) / 1.25 + bias, 0.0), 0.999) * levels
    index = int(value)
    if value - index > BAYER[y % 2][x % 2]:
        index += 1
    return min(index, levels - 1)


def blob(cell, circles, palette, dashes=0, bias=0.0):
    """Uma forma de círculos (cx, cy, r): os de baixo ficam na frente, com a borda de cima
    deles marcada; o contorno é a primeira cor da paleta."""
    owner = {}
    for index, (cx, cy, r) in enumerate(circles):
        for y in range(int(cy - r) - 1, int(cy + r) + 2):
            for x in range(int(cx - r) - 1, int(cx + r) + 2):
                if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                    best = owner.get((x, y))
                    if best is None or circles[best][1] < cy:
                        owner[(x, y)] = index
    tones = palette[1:]
    for (x, y), index in owner.items():
        cx, cy, r = circles[index]
        edge = any((x + dx, y + dy) not in owner for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if edge:
            cell.put(x, y, palette[0])
            continue
        above = owner.get((x, y - 1))
        if above is not None and above != index and circles[above][1] < cy:
            cell.put(x, y, tones[1] if len(tones) > 4 else tones[0])
            continue
        cell.put(x, y, tones[shade_index((x + 0.5 - cx) / r, (y + 0.5 - cy) / r, len(tones), x, y, bias)])
    inside = [spot for spot in owner if cell.pixels.get(spot) not in (palette[0],)]
    for _ in range(dashes):
        x, y = cell.rng.choice(sorted(inside))
        if all((x + k, y) in owner and cell.pixels[(x + k, y)] != palette[0] for k in range(3)):
            for k in range(2 + cell.rng.randrange(2)):
                if cell.pixels[(x + k, y)] != palette[0]:
                    cell.put(x + k, y, tones[0])
    return owner


def trunk(cell, x, top, bottom, width, bark):
    for y in range(top, bottom + 1):
        for k in range(width):
            color = bark[1] if k == width - 1 else (bark[3] if k == 0 and width > 2 else bark[2])
            cell.put(x + k, y, color)


def line(cell, x0, y0, x1, y1, color, width=1):
    steps = max(abs(x1 - x0), abs(y1 - y0), 1)
    points = []
    for step in range(steps + 1):
        x = round(x0 + (x1 - x0) * step / steps)
        y = round(y0 + (y1 - y0) * step / steps)
        points.append((x, y))
        for k in range(1, width):
            cell.put(x, y - k, color)
        cell.put(x, y, color)
    return points


def branch(cell, palette, leaves=None, snow=False):
    """Um galho deitado, com dois ou três raminhos, o contorno e a luz por cima."""
    rng = cell.rng
    length = rng.randint(18, 24)
    tilt = rng.choice([-3, -2, 2, 3])
    x0 = BASE[0] - length // 2
    y0 = BASE[1] - 1 - max(tilt, 0)
    x1, y1 = x0 + length, y0 + tilt
    body = set()
    for x, y in line(cell, x0, y0, x1, y1, palette[2], 2):
        body.update({(x, y), (x, y - 1)})
    twigs = []
    for _ in range(rng.randint(2, 3)):
        t = rng.uniform(0.25, 0.8)
        sx, sy = round(x0 + (x1 - x0) * t), round(y0 + (y1 - y0) * t) - 1
        ex, ey = sx + rng.choice([-1, 1]) * rng.randint(2, 5), sy - rng.randint(3, 6)
        for spot in line(cell, sx, sy, ex, ey, palette[2]):
            body.add(spot)
        twigs.append((ex, ey))
    for x, y in sorted(body):
        if (x, y - 1) not in body:
            cell.put(x, y, palette[3])
        elif (x, y + 1) not in body:
            cell.put(x, y, palette[1])
    for x, y in sorted(body):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if (x + dx, y + dy) not in body and (x + dx, y + dy) not in cell.pixels:
                cell.put(x + dx, y + dy, palette[0])
    if leaves:
        for ex, ey in twigs:
            for dx, dy in ((0, 0), (1, 0), (0, -1)):
                cell.put(ex + dx, ey + dy, leaves[rng.randrange(len(leaves))])
    if snow:
        for x, y in sorted(body):
            if (x, y - 1) not in body and rng.random() < 0.8:
                cell.put(x, y - 1, SNOW[2])
                if (x, y - 2) not in body:
                    cell.put(x, y - 2, SNOW[1] if rng.random() < 0.5 else SNOW[2])


def blades(cell, palette, count, height, spread, lean=2, heads=None):
    rng = cell.rng
    for _ in range(count):
        x0 = BASE[0] + rng.randint(-spread, spread)
        h = rng.randint(height[0], height[1])
        bend = rng.uniform(-lean, lean)
        top = None
        for step in range(h):
            t = step / max(h - 1, 1)
            x = round(x0 + bend * t * t)
            y = BASE[1] - step
            cell.put(x, y, palette[min(int(t * len(palette)), len(palette) - 1)])
            top = (x, y)
        if heads and top:
            heads(top)


def tree(cell, leaves, bark, height, width, clusters, trunk_width, trunk_length, bark_marks=False):
    rng = cell.rng
    cx = BASE[0]
    top = BASE[1] - height
    canopy_bottom = BASE[1] - trunk_length
    trunk(cell, cx - trunk_width // 2, canopy_bottom - 6, BASE[1], trunk_width, bark)
    if bark_marks:
        for y in range(canopy_bottom - 2, BASE[1], 3):
            if rng.random() < 0.8:
                cell.put(cx - trunk_width // 2 + rng.randrange(trunk_width), y, bark[0])
    span = canopy_bottom - top
    circles = []
    for _ in range(clusters):
        r = rng.uniform(width * 0.24, width * 0.32)
        circles.append((cx + rng.uniform(-(width / 2 - r), width / 2 - r), rng.uniform(top + r, canopy_bottom - r), r))
    circles.append((cx + rng.uniform(-1.5, 1.5), top + span * 0.55, min(width * 0.4, span * 0.42)))
    blob(cell, circles, leaves, dashes=rng.randint(4, 7))


def birch(cell, variant):
    rng = cell.rng
    tree(cell, BIRCH_LEAVES, BIRCH_BARK, rng.randint(42, 46), rng.randint(16, 19), 6, 3, rng.randint(11, 14), bark_marks=True)
    return (8, 2)


def oak(cell, variant):
    rng = cell.rng
    tree(cell, OAK_LEAVES, BARK, rng.randint(38, 42), rng.randint(32, 36), 7, 4, rng.randint(8, 10))
    return (14, 3)


def fir(cell, variant):
    rng = cell.rng
    height = rng.randint(40, 46)
    half_base = rng.randint(8, 10)
    tiers = rng.randint(4, 5)
    cx = BASE[0]
    trunk(cell, cx - 1, BASE[1] - 4, BASE[1], 2, BARK)
    top = BASE[1] - height
    bottom = BASE[1] - 3
    shape = {}
    for y in range(top, bottom + 1):
        t = (y - top) / (bottom - top)
        tier = (t * tiers) % 1.0
        half = half_base * (0.2 + 0.8 * t) * (0.55 + 0.45 * tier) + 0.5
        for x in range(round(cx - half), round(cx + half) + 1):
            shape[(x, y)] = half
    tones = FIR_LEAVES[1:]
    for (x, y), half in shape.items():
        if any((x + dx, y + dy) not in shape for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            cell.put(x, y, FIR_LEAVES[0])
            continue
        nx = (x + 0.5 - cx) / max(half + 0.5, 1.0)
        tier = (((y - top) / (bottom - top)) * tiers) % 1.0
        if tier > 0.82 and (x + y) % 2 == 0 and (x, y + 1) in shape:
            cell.put(x, y, tones[0])
            continue
        cell.put(x, y, tones[shade_index(nx * 0.9, -0.7 + tier * 1.2, len(tones), x, y)])
    return (7, 2)


def fallen_branch(cell, variant):
    branch(cell, BARK, leaves=[(74, 160, 68), (109, 187, 80)] if variant % 2 == 0 else None)
    return (11, 2)


def dry_branch(cell, variant):
    branch(cell, DRY_BARK)
    return (11, 2)


def bleached_branch(cell, variant):
    branch(cell, BLEACHED)
    return (11, 2)


def frozen_branch(cell, variant):
    branch(cell, FROZEN, snow=True)
    return (11, 2)


def log(cell, variant, snow=False):
    rng = cell.rng
    length = rng.randint(20, 25)
    radius = rng.choice([3, 4])
    x0 = BASE[0] - length // 2
    x1 = x0 + length - 1
    cy = BASE[1] - radius
    top, bottom = cy - radius, cy + radius
    for x in range(x0, x1 + 1):
        for y in range(top, bottom + 1):
            if x in (x0, x1) and y in (top, bottom):
                continue
            if y in (top, bottom) or x in (x0, x1):
                cell.put(x, y, BARK[0])
                continue
            band = (y - top) / (bottom - top)
            cell.put(x, y, BARK[3] if band < 0.3 else (BARK[2] if band < 0.65 else BARK[1]))
    for _ in range(length // 2):
        x = rng.randint(x0 + 2, x1 - 4)
        y = rng.randint(top + 2, bottom - 1)
        for k in range(rng.randint(2, 3)):
            cell.put(x + k, y, BARK[1] if y > cy else BARK[2])
    cut, step = (x1, -1) if variant % 2 == 0 else (x0, 1)
    for y in range(top + 1, bottom):
        ring = abs(y - cy)
        cell.put(cut + step, y, WOOD_END[1] if ring < radius - 1 else BARK[0])
        cell.put(cut, y, BARK[0])
        if ring < radius - 1:
            cell.put(cut + 2 * step, y, WOOD_END[2] if ring == 0 else WOOD_END[0])
    if variant >= 2 and not snow:
        for x in range(x0 + 2, x1 - 2):
            if rng.random() < 0.45:
                cell.put(x, top, (74, 150, 70))
                if rng.random() < 0.4:
                    cell.put(x, top - 1, (109, 187, 80))
    if snow:
        for x in range(x0 + 1, x1):
            cell.put(x, top, SNOW[2])
            if rng.random() < 0.75:
                cell.put(x, top - 1, SNOW[1 if rng.random() < 0.4 else 2])
            if rng.random() < 0.3:
                cell.put(x, top + 1, SNOW[0])
    return (length // 2 + 1, 2)


def snow_log(cell, variant):
    return log(cell, variant, snow=True)


def stump(cell, variant):
    rng = cell.rng
    width = rng.choice([9, 11])
    height = rng.randint(5, 7)
    x0 = BASE[0] - width // 2
    x1 = x0 + width - 1
    top = BASE[1] - height
    for x in range(x0, x1 + 1):
        for y in range(top, BASE[1] + 1):
            if x in (x0, x1) or y == BASE[1]:
                cell.put(x, y, BARK[0])
                continue
            third = (x - x0) / width
            color = BARK[3] if third < 0.34 else (BARK[2] if third < 0.67 else BARK[1])
            cell.put(x, y, BARK[1] if (x - x0) % 3 == 0 else color)
    for y in (top - 2, top - 1, top):
        inset = 1 if y == top - 2 else 0
        for x in range(x0 + inset, x1 - inset + 1):
            edge = x in (x0 + inset, x1 - inset) or y == top - 2
            cell.put(x, y, BARK[0] if edge else WOOD_END[1])
    for x in range(x0 + 2, x1 - 1):
        cell.put(x, top - 1, WOOD_END[2])
    cell.put(BASE[0], top - 1, WOOD_END[0])
    cell.put(BASE[0] - 1, top, WOOD_END[0])
    cell.put(BASE[0] + 1, top, WOOD_END[0])
    for side, edge in ((-1, x0), (1, x1)):
        cell.put(edge + side, BASE[1], BARK[1])
        cell.put(edge + 2 * side, BASE[1], BARK[0])
        cell.put(edge + side, BASE[1] - 1, BARK[0])
    if variant == 3:
        for x in range(x0 + 1, x1):
            if rng.random() < 0.5:
                cell.put(x, top - 2, (74, 150, 70))
    return (width // 2 + 2, 2)


MUSHROOM_CAPS = [
    [(110, 26, 30), (196, 48, 46), (230, 92, 76)],
    [(78, 52, 34), (140, 98, 62), (184, 140, 92)],
    [(120, 90, 54), (196, 160, 104), (232, 204, 150)],
    [(110, 26, 30), (196, 48, 46), (230, 92, 76)],
]


def mushrooms(cell, variant):
    rng = cell.rng
    caps = MUSHROOM_CAPS[variant]
    for _ in range(rng.randint(2, 3)):
        x = BASE[0] + rng.randint(-5, 5)
        size = rng.choice([2, 3])
        stem = rng.randint(2, 3)
        for y in range(BASE[1] - stem, BASE[1] + 1):
            cell.put(x, y, (226, 220, 200) if y < BASE[1] else (170, 160, 140))
        cy = BASE[1] - stem - 1
        for dx in range(-size, size + 1):
            cell.put(x + dx, cy, caps[0] if abs(dx) == size else caps[1])
        for dx in range(-size + 1, size):
            cell.put(x + dx, cy - 1, caps[0] if abs(dx) == size - 1 else caps[2])
        if variant in (0, 3) and size == 3:
            cell.put(x - 1, cy, (245, 242, 228))
            cell.put(x + 1, cy - 1, (245, 242, 228))
    return (6, 2)


def tall_grass(cell, variant):
    seeds = variant >= 2

    def head(top):
        if seeds:
            cell.put(top[0], top[1] - 1, DRY_GRASS[3])
            cell.put(top[0], top[1] - 2, DRY_GRASS[2])

    blades(cell, GRASS, cell.rng.randint(7, 10), (9, 15), 5, lean=3, heads=head)
    return (7, 2)


def wildflowers(cell, variant):
    rng = cell.rng
    colors = [(150, 110, 210), (96, 140, 230), (245, 242, 228), (233, 140, 192), (244, 201, 54)]
    rng.shuffle(colors)

    def head(top):
        color = colors[rng.randrange(3)]
        for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 0)):
            cell.put(top[0] + dx, top[1] + dy, color)

    blades(cell, STEM, rng.randint(5, 7), (5, 10), 7, lean=2, heads=head)
    return (8, 2)


def clover(cell, variant):
    rng = cell.rng
    leaf = [(40, 104, 42), (74, 154, 64), (120, 196, 90)]
    for _ in range(rng.randint(9, 12)):
        x = BASE[0] + rng.randint(-8, 8)
        y = BASE[1] - rng.randint(-1, 2)
        for dx, dy, tone in ((0, -2, 2), (-1, -1, 1), (1, -1, 1), (0, -1, 0), (-1, -2, 2), (1, -2, 1), (0, -3, 2)):
            cell.put(x + dx, y + dy, leaf[tone])
        cell.put(x, y, leaf[0])
    if variant >= 2:
        for _ in range(2):
            cell.put(BASE[0] + rng.randint(-6, 6), BASE[1] - rng.randint(3, 4), (245, 242, 228))
    return (10, 2)


def bush(cell, palette, berries, snow=False):
    rng = cell.rng
    width = rng.randint(17, 22)
    circles = []
    for _ in range(rng.randint(3, 4)):
        r = rng.uniform(5.0, 7.0)
        circles.append((BASE[0] + rng.uniform(-width * 0.2, width * 0.2), BASE[1] - r - rng.uniform(0.5, 3), r))
    owner = blob(cell, circles, palette, dashes=2)
    inside = [spot for spot in sorted(owner) if cell.pixels[spot] != palette[0]]
    for _ in range(rng.randint(5, 8)):
        x, y = rng.choice(inside)
        cell.put(x, y, berries[1])
        cell.put(x + 1, y, berries[0])
    if snow:
        for (x, y) in sorted(owner):
            if (x, y - 1) not in owner:
                cell.put(x, y, SNOW[2])
                if (x, y + 1) in owner and rng.random() < 0.6:
                    cell.put(x, y + 1, SNOW[1])
    return (width // 2, 2)


def berry_bush(cell, variant):
    return bush(cell, BERRY_LEAVES, [(52, 44, 120), (120, 110, 214)])


def winter_berry(cell, variant):
    return bush(cell, WINTER_LEAVES, [(120, 20, 28), (220, 52, 52)], snow=True)


def thistle(cell, variant):
    rng = cell.rng
    stem = [(76, 112, 78), (130, 168, 116)]
    heads = [(96, 40, 110), (170, 84, 180), (220, 146, 226)]

    def head(top):
        x, y = top
        cell.put(x - 1, y, (90, 130, 84))
        cell.put(x + 1, y, (90, 130, 84))
        for dx in (-1, 0, 1):
            cell.put(x + dx, y - 1, heads[1])
            cell.put(x + dx, y - 2, heads[2] if dx < 1 else heads[1])
        for dx in (-1, 1):
            cell.put(x + dx, y - 3, heads[0])
        cell.put(x, y - 3, heads[2])

    blades(cell, stem, rng.randint(2, 3), (9, 14), 4, lean=2, heads=head)
    for dx in range(-5, 6):
        cell.put(BASE[0] + dx, BASE[1], stem[0])
        if abs(dx) < 5 and (dx % 2 == 0 or abs(dx) < 2):
            cell.put(BASE[0] + dx, BASE[1] - 1, stem[1])
        if abs(dx) in (2, 4):
            cell.put(BASE[0] + dx + (1 if dx > 0 else -1), BASE[1] - 2, stem[1])
    return (6, 2)


def yellow_flowers(cell, variant):
    rng = cell.rng
    heads = [(230, 170, 40), (250, 214, 70), (240, 130, 50)]

    def head(top):
        color = heads[rng.randrange(2)] if variant < 3 else heads[2]
        for dx, dy in ((0, -1), (-1, 0), (1, 0)):
            cell.put(top[0] + dx, top[1] + dy, color)
        cell.put(top[0], top[1], (150, 90, 30))

    blades(cell, [DRY_GRASS[0], DRY_GRASS[1]], rng.randint(3, 5), (5, 9), 6, lean=2, heads=head)
    return (7, 2)


def facet_rock(cell, palette, width, height, cracks=1, flat=False):
    """Uma pedra de facetas: a frente mais escura, o topo claro e rachaduras."""
    rng = cell.rng
    cx = BASE[0]
    bottom = BASE[1]
    shape = {}
    for y in range(bottom - height, bottom + 1):
        t = (y - (bottom - height)) / height
        curve = math.sqrt(max(0.0, 1.0 - (1.0 - t) ** 2)) if not flat else min(1.0, t * 3.0)
        half = width / 2 * curve
        wobble = rng.choice([0, 0, 1])
        for x in range(round(cx - half) + wobble, round(cx + half) + 1):
            shape[(x, y)] = t
    tones = palette[1:]
    for (x, y), t in shape.items():
        if any((x + dx, y + dy) not in shape for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            cell.put(x, y, palette[0])
            continue
        nx = (x + 0.5 - cx) / (width / 2)
        ny = -0.9 + 1.5 * t if not flat else (-0.95 if t < 0.45 else 0.5)
        cell.put(x, y, tones[shade_index(nx * 0.8, max(-0.95, min(0.95, ny)), len(tones), x, y)])
    for _ in range(cracks):
        x = cx + rng.randint(-width // 4, width // 4)
        y = bottom - height + rng.randint(2, max(3, height // 2))
        for _ in range(rng.randint(3, 5)):
            if (x, y) in shape and cell.pixels[(x, y)] != palette[0]:
                cell.put(x, y, palette[1])
            x += rng.choice([-1, 0, 1])
            y += 1
    return shape


def slab(cell, variant):
    width = cell.rng.randint(20, 25)
    facet_rock(cell, STONE, width, cell.rng.randint(6, 8), cracks=2, flat=True)
    return (width // 2 + 1, 2)


def lichen_rock(cell, variant):
    width = cell.rng.randint(15, 19)
    shape = facet_rock(cell, STONE, width, cell.rng.randint(9, 12))
    inside = [spot for spot in sorted(shape) if cell.pixels[spot] != STONE[0]]
    for _ in range(cell.rng.randint(5, 8)):
        x, y = cell.rng.choice(inside[: len(inside) * 2 // 3])
        for dx, dy in ((0, 0), (1, 0), (0, 1)):
            if (x + dx, y + dy) in shape and cell.pixels[(x + dx, y + dy)] != STONE[0]:
                cell.put(x + dx, y + dy, LICHEN[cell.rng.randrange(3)])
    return (width // 2, 2)


def tumbleweed(cell, variant):
    rng = cell.rng
    r = rng.uniform(5.5, 7.5)
    cx, cy = BASE[0], BASE[1] - r
    for _ in range(44):
        a = rng.uniform(0, math.tau)
        b = a + rng.uniform(0.6, 1.8)
        rr = r * rng.uniform(0.15, 1.0)
        x0, y0 = cx + math.cos(a) * rr, cy + math.sin(a) * rr
        x1, y1 = cx + math.cos(b) * rr, cy + math.sin(b) * rr
        color = TUMBLE[rng.randrange(1, 4)]
        line(cell, round(x0), round(y0), round(x1), round(y1), color)
    for (x, y), color in list(cell.pixels.items()):
        if ((x - cx) / r) ** 2 + ((y - cy) / r) ** 2 > 0.75 and color != TUMBLE[3]:
            cell.put(x, y, TUMBLE[0])
    return (round(r), 2)


def desert_flower(cell, variant):
    rng = cell.rng
    petals = [[(200, 60, 120), (240, 110, 170)], [(220, 110, 40), (250, 170, 70)], [(200, 60, 120), (240, 110, 170)], [(240, 220, 120), (252, 246, 196)]][variant]
    leaf = [(70, 104, 76), (110, 146, 104)]
    for dx in range(-3, 4):
        cell.put(BASE[0] + dx, BASE[1], leaf[0])
        if abs(dx) < 3:
            cell.put(BASE[0] + dx, BASE[1] - 1, leaf[1] if dx < 0 else leaf[0])
    for side in (-1, 1):
        cell.put(BASE[0] + side * 3, BASE[1] - 2, leaf[1])
    stem = rng.randint(3, 5)
    for y in range(BASE[1] - stem, BASE[1] - 1):
        cell.put(BASE[0], y, leaf[0])
    top = BASE[1] - stem - 1
    for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1), (-1, -1), (1, -1)):
        cell.put(BASE[0] + dx, top + dy, petals[1] if dy < 0 else petals[0])
    cell.put(BASE[0], top, (250, 220, 80))
    return (4, 1)


def dune_grass(cell, variant):
    blades(cell, DUNE_GRASS, cell.rng.randint(5, 8), (6, 11), 4, lean=4)
    return (6, 2)


def ice_shards(cell, variant):
    rng = cell.rng
    for _ in range(rng.randint(2, 4)):
        x = BASE[0] + rng.randint(-6, 6)
        height = rng.randint(5, 12)
        lean = rng.choice([-2, -1, 0, 1, 2])
        half = rng.choice([1, 2])
        for step in range(height):
            t = step / height
            cx = round(x + lean * t)
            w = max(0, round(half * (1 - t)))
            y = BASE[1] - step
            for dx in range(-w - 1, w + 2):
                edge = abs(dx) == w + 1
                color = ICE[0] if edge else (ICE[3] if dx < 0 else (ICE[4] if dx == 0 and step % 3 == 1 else ICE[2]))
                if not (edge and (cx + dx, y) in cell.pixels and cell.pixels[(cx + dx, y)] != ICE[0]):
                    cell.put(cx + dx, y, color)
        cell.put(round(x + lean), BASE[1] - height, ICE[0])
    return (7, 2)


KINDS = [
    birch, oak, fir, fallen_branch, log, stump, mushrooms, tall_grass, wildflowers, clover,
    berry_bush, thistle, dry_branch, yellow_flowers, slab, lichen_rock, tumbleweed,
    desert_flower, bleached_branch, dune_grass, frozen_branch, ice_shards, winter_berry, snow_log,
]


def main():
    file = path("decorations", "decorations.png")
    sheet = Image.open(file).convert("RGBA")
    needed = (FIRST_ROW + len(KINDS)) * CELL[1]
    grown = Image.new("RGBA", (sheet.width, max(needed, sheet.height)), (0, 0, 0, 0))
    grown.paste(sheet, (0, 0))
    grown.paste(Image.new("RGBA", (sheet.width, needed - FIRST_ROW * CELL[1]), (0, 0, 0, 0)), (0, FIRST_ROW * CELL[1]))
    for row, kind in enumerate(KINDS):
        for variant in range(4):
            cell = Cell(random.Random(f"{kind.__name__}:{variant}"))
            shadow = kind(cell, variant)
            grown.paste(cell.image(shadow), (variant * CELL[0], (FIRST_ROW + row) * CELL[1]))
    grown.save(file)


if __name__ == "__main__":
    main()
    print("ok")
