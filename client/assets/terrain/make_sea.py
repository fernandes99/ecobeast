"""Desenha os 13 tipos de decoração da água (.specs/sea-life/01-sea-art.md).

Uso: python -I make_sea.py   (precisa do Pillow; roda de dentro de assets/terrain)

Cada tipo é uma linha de decorations/decorations.png (51 a 63), com 4 variantes, no traço
do make_nature.py. O que fica embaixo d'água é meio transparente, para a água aparecer, e o
que fura a superfície ganha a espuma. Rodar de novo regrava só essas linhas.
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

FIRST_ROW = 51
BX, BY = nature.BASE

FOAM = (238, 250, 255, 230)
FOAM_SOFT = (214, 240, 252, 150)
SEA_ROCK = [(26, 32, 38), (50, 60, 68), (72, 84, 92), (96, 108, 114), (126, 136, 140), (164, 172, 174)]
STACK_ROCK = [(30, 30, 34), (58, 58, 62), (82, 82, 86), (108, 106, 106), (138, 134, 130), (174, 168, 160)]
BARNACLE = [(200, 196, 184), (236, 232, 222)]
WET_MOSS = [(30, 78, 52), (52, 112, 64), (84, 146, 78)]
SEAGRASS = [(18, 70, 52), (30, 98, 64), (50, 130, 76), (92, 172, 92), (148, 206, 120)]
ALGAE = [(14, 58, 44), (26, 86, 56), (44, 116, 66), (80, 150, 82)]
KELP = [(16, 30, 20), (34, 58, 34), (52, 84, 44), (76, 112, 56), (108, 140, 72)]
KELP_FLOAT = [(40, 52, 22), (96, 112, 46), (140, 150, 70)]
BLADDER = [(120, 92, 30), (206, 172, 72), (240, 214, 120)]
SARGASSUM = [(66, 46, 12), (122, 90, 26), (170, 134, 46), (210, 180, 80), (238, 214, 130)]
GLASS = [(24, 60, 44), (58, 124, 86), (110, 180, 132), (176, 226, 190), (236, 252, 240)]
CORK = [(92, 60, 30), (150, 106, 60)]
CAN_RED = [(56, 18, 18), (150, 36, 36), (204, 72, 64), (236, 128, 112)]
CAN_BLUE = [(18, 30, 58), (40, 72, 140), (74, 116, 190), (130, 170, 226)]
METAL = [(120, 124, 130), (190, 194, 200), (238, 240, 244)]
BAG = [(150, 164, 172, 170), (206, 216, 222, 160), (238, 244, 246, 180), (255, 255, 255, 210)]
ROPE = [(40, 64, 66), (82, 122, 118), (132, 170, 156)]
NET_FLOAT = [(98, 26, 18), (214, 78, 40), (250, 150, 90), (255, 214, 170)]
TIRE = [(12, 12, 14), (30, 30, 34), (50, 50, 56), (76, 76, 84)]
CRATE = [(50, 34, 18), (98, 68, 38), (140, 102, 60), (180, 142, 90), (212, 180, 124)]


class SeaCell(nature.Cell):
    """Uma célula que aceita cor com alfa e não tem a sombra no pé."""

    def image(self, shadow=None):
        cell = Image.new("RGBA", nature.CELL, (0, 0, 0, 0))
        data = cell.load()
        for (x, y), color in self.pixels.items():
            data[x, y] = tuple(color) if len(color) == 4 else tuple(color) + (255,)
        return cell


def under(color, alpha, depth=0.35):
    """A cor vista embaixo d'água: puxada para o azul-esverdeado e transparente."""
    r, g, b = color[:3]
    tint = (20, 70, 90)
    mixed = tuple(round(c * (1 - depth) + t * depth) for c, t in zip((r, g, b), tint))
    return mixed + (alpha,)


def sink(cell, waterline, alpha=150, fade=40):
    """Afunda o que está abaixo da linha d'água: quanto mais fundo, mais transparente."""
    for (x, y), color in list(cell.pixels.items()):
        if y > waterline and len(color) == 3:
            depth = y - waterline
            cell.pixels[(x, y)] = under(color, max(60, alpha - fade * (depth - 1) // 3), min(0.6, 0.25 + 0.06 * depth))


def opaque(cell, x, y):
    color = cell.pixels.get((x, y))
    return color is not None and (len(color) == 3 or color[3] >= 200)


def foam_ring(cell, cx, cy, rx, ry, gaps=0.2, front_only=False):
    """O anel de espuma em volta do que fura a água: na frente por cima, atrás só no vazio."""
    rng = cell.rng
    steps = max(24, int(2 * math.pi * max(rx, ry)))
    for step in range(steps):
        t = 2 * math.pi * step / steps
        x = round(cx + rx * math.cos(t))
        y = round(cy + ry * math.sin(t))
        front = y >= cy
        if front_only and not front:
            continue
        if rng.random() < gaps:
            continue
        if front or not opaque(cell, x, y):
            cell.put(x, y, FOAM if rng.random() < 0.7 else FOAM_SOFT)


def ripple(cell, cx, cy, rx, ry):
    """Um anel fraco e partido de água mexida, só no vazio."""
    rng = cell.rng
    for step in range(28):
        t = 2 * math.pi * step / 28
        if rng.random() < 0.45:
            continue
        x, y = round(cx + rx * math.cos(t)), round(cy + ry * math.sin(t))
        if (x, y) not in cell.pixels:
            cell.put(x, y, FOAM_SOFT)


def ellipse(cell, cx, cy, rx, ry, color_at):
    spots = []
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                spots.append((x, y))
    shape = set(spots)
    for x, y in spots:
        edge = any((x + dx, y + dy) not in shape for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        color = color_at(x, y, edge)
        if color is not None:
            cell.put(x, y, color)
    return shape


def seagrass(cell, variant):
    rng = cell.rng
    for _ in range(rng.randint(9, 13)):
        x0 = BX + rng.randint(-9, 9)
        y0 = BY + rng.randint(-2, 2)
        h = rng.randint(6, 12)
        bend = rng.uniform(-4, 4)
        for step in range(h):
            t = step / max(h - 1, 1)
            x, y = round(x0 + bend * t * t), y0 - step
            if step >= h - 3:
                cell.put(x, y, SEAGRASS[2 + min(step - (h - 3), 2)])
            else:
                cell.put(x, y, under(SEAGRASS[1 + (step * 2 // h)], 150 + step * 8, 0.25))
    ripple(cell, BX, BY - 2, 10, 3)
    return None

def kelp(cell, variant):
    rng = cell.rng
    cx, cy = BX + rng.randint(-2, 2), BY - 4
    for _ in range(rng.randint(2, 3)):
        sx = cx + rng.randint(-3, 3)
        nature_line = [(sx + round(math.sin(k * 0.7) * 1.2), cy + k) for k in range(1, 9)]
        for x, y in nature_line:
            cell.put(x, y, under(KELP[1], 120 - (y - cy) * 6, 0.45))
    leaves = rng.randint(5, 7)
    start = rng.uniform(0, math.tau)
    for index in range(leaves):
        angle = start + math.tau * index / leaves + rng.uniform(-0.3, 0.3)
        length = rng.uniform(9, 14)
        dx, dy = math.cos(angle), math.sin(angle) * 0.5
        for step in range(int(length)):
            t = step / length
            half = 1.6 * math.sin(math.pi * min(1.0, t * 1.15 + 0.05))
            px, py = cx + dx * step, cy + dy * step
            for side in range(-2, 3):
                if abs(side) > half + 0.2:
                    continue
                x, y = round(px - dy * side), round(py + dx * side * 0.6)
                edge = abs(side) >= half - 0.5
                tone = KELP[1] if edge else (KELP[3] if side == 0 else KELP[2])
                if y >= cy + 2 and not edge:
                    tone = under(tone, 190, 0.2)
                cell.put(x, y, tone)
        bx, by = round(cx + dx * 3), round(cy + dy * 3) - 1
        cell.put(bx, by, KELP_FLOAT[1])
    for dx, dy, tone in ((0, 0, 2), (1, 0, 1), (0, 1, 1), (1, 1, 0)):
        cell.put(cx + dx, cy - 1 + dy, KELP_FLOAT[tone])
    ripple(cell, cx, cy + 1, 12, 4)
    return None

def algae_patch(cell, variant):
    rng = cell.rng
    blobs = [(BX + rng.randint(-8, 8), BY - rng.randint(0, 4), rng.uniform(3.5, 6.5)) for _ in range(rng.randint(4, 6))]
    owner = set()
    for cx, cy, r in blobs:
        for y in range(int(cy - r / 2) - 1, int(cy + r / 2) + 2):
            for x in range(int(cx - r) - 1, int(cx + r) + 2):
                if ((x + 0.5 - cx) / r) ** 2 + ((y + 0.5 - cy) / (r / 2)) ** 2 <= 1.0:
                    owner.add((x, y))
    for x, y in sorted(owner):
        edge = any((x + dx, y + dy) not in owner for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if edge:
            cell.put(x, y, under(ALGAE[0], 140, 0.2))
        elif (x, y - 1) not in owner or rng.random() < 0.25:
            cell.put(x, y, under(ALGAE[2 + rng.randrange(2)], 140, 0.2))
        else:
            cell.put(x, y, under(ALGAE[1], 125, 0.2))
    return None

def sea_rock(cell, variant):
    rng = cell.rng
    width = rng.randint(12, 17)
    height = rng.randint(8, 11)
    shape = nature.facet_rock(cell, SEA_ROCK, width, height)
    waterline = BY - 2
    for x, y in sorted(shape):
        if y == waterline - 1 and rng.random() < 0.6 and cell.pixels[(x, y)] != SEA_ROCK[0]:
            cell.put(x, y, WET_MOSS[rng.randrange(3)])
    sink(cell, waterline, 160)
    foam_ring(cell, BX, waterline + 1, width / 2 + 1.5, 2.2, 0.15)
    ripple(cell, BX, waterline + 1, width / 2 + 4, 3.6)
    return None


def sunken_rock(cell, variant):
    rng = cell.rng
    circles = [(BX + rng.uniform(-6, 6), BY - 2 + rng.uniform(-1.5, 1.0), rng.uniform(4.5, 6.5)) for _ in range(rng.randint(3, 4))]
    circles = [(x, y, r) for x, y, r in circles]
    owner = nature.blob(cell, circles, SEA_ROCK, bias=-0.05)
    for (x, y), color in list(cell.pixels.items()):
        squashed = BY - 2 + round((y - (BY - 2)) * 0.75)
        del cell.pixels[(x, y)]
        cell.pixels.setdefault((x, squashed), under(color, 130 if color != SEA_ROCK[0] else 150, 0.5))
    for _ in range(rng.randint(2, 3)):
        x, y = rng.choice(sorted(cell.pixels))
        cell.put(x, y, (200, 236, 250, 110))
    return None

def sea_stack(cell, variant):
    rng = cell.rng
    width = rng.randint(14, 18)
    height = rng.randint(22, 30)
    shape = nature.facet_rock(cell, STACK_ROCK, width, height, cracks=2)
    waterline = BY - 2
    inside = [spot for spot in sorted(shape) if cell.pixels[spot] != STACK_ROCK[0]]
    columns = {}
    for x, y in inside:
        columns.setdefault(x, []).append(y)
    for x, ys in columns.items():
        band = 3 + (x * 7 + variant) % 3
        for y in ys:
            if waterline - band <= y < waterline:
                cell.put(x, y, WET_MOSS[0] if y >= waterline - 1 else WET_MOSS[1 + (y + x) % 2])
            elif y == waterline - band - 1 and x % 2 == 0:
                cell.put(x, y, WET_MOSS[2])
    for _ in range(rng.randint(5, 8)):
        x, y = rng.choice(inside)
        if waterline - 12 <= y < waterline - 6:
            cell.put(x, y, BARNACLE[rng.randrange(2)])
    sink(cell, waterline, 160)
    foam_ring(cell, BX, waterline + 1, width / 2 + 1.5, 2.4, 0.1)
    ripple(cell, BX, waterline + 1, width / 2 + 4, 3.8)
    return None

def floating_weed(cell, variant):
    rng = cell.rng
    circles = [(BX + rng.uniform(-8, 8), BY - 2 + rng.uniform(-2, 2), rng.uniform(1.4, 2.4)) for _ in range(rng.randint(8, 12))]
    owner = nature.blob(cell, circles, SARGASSUM, bias=0.05)
    for _ in range(rng.randint(5, 8)):
        x, y = rng.choice(sorted(owner))
        if cell.pixels.get((x, y)) != SARGASSUM[0]:
            cell.put(x, y, SARGASSUM[4])
    for (x, y) in sorted(owner):
        if (x, y + 1) not in owner:
            cell.put(x, y + 1, under(SARGASSUM[1], 120, 0.4))
    ripple(cell, BX, BY - 1, 11, 3.5)
    return None

def bottle(cell, variant):
    rng = cell.rng
    direction = 1 if variant % 2 == 0 else -1
    length = rng.randint(7, 9)
    x0 = BX - direction * (length // 2)
    y = BY - 2
    glass = GLASS if variant < 2 else [(52, 40, 22), (110, 80, 36), (164, 120, 56), (210, 170, 100), (246, 226, 180)]
    for step in range(length):
        x = x0 + direction * step
        neck = step >= length - 3
        rows = (0,) if neck else (-1, 0, 1)
        for dy in rows:
            if dy == -1:
                color = glass[3]
            elif dy == 0:
                color = glass[2] if not neck else glass[1]
            else:
                color = glass[1]
            cell.put(x, y + dy, color)
        if not neck:
            cell.put(x, y - 2, glass[0])
            cell.put(x, y + 2, under(glass[0], 140, 0.3))
    cell.put(x0 + direction * 1, y - 1, glass[4])
    cell.put(x0 + direction * 2, y - 1, glass[4])
    tip = x0 + direction * length
    cell.put(tip, y, CORK[1])
    cell.put(tip, y - 1, CORK[0])
    cell.put(x0 - direction, y, glass[0])
    cell.put(x0 - direction, y - 1, glass[0])
    sink(cell, y, 150)
    foam_ring(cell, BX, y + 1, length / 2 + 1.5, 1.6, 0.35, front_only=True)
    ripple(cell, BX, y + 1, length / 2 + 4, 2.8)
    return None


def can(cell, variant):
    rng = cell.rng
    body = CAN_RED if variant % 2 == 0 else CAN_BLUE
    y = BY - 2
    x0 = BX - 3
    for step in range(6):
        x = x0 + step
        end = step in (0, 5)
        dent = step == 3 and variant >= 2
        cell.put(x, y - 1 + (1 if dent else 0), METAL[1] if end else body[3])
        cell.put(x, y, METAL[0] if end else body[2])
        cell.put(x, y + 1, METAL[0] if end else body[1])
        cell.put(x, y - 2 + (1 if dent else 0), body[0] if not end else METAL[0])
    cell.put(x0 + 2, y, METAL[2])
    cell.put(x0 - 1, y, body[0])
    cell.put(x0 + 6, y, body[0])
    sink(cell, y, 160)
    foam_ring(cell, BX, y + 1, 4.5, 1.4, 0.35, front_only=True)
    ripple(cell, BX, y + 1, 7, 2.6)
    return None


def plastic_bag(cell, variant):
    rng = cell.rng
    cx, cy = BX + rng.randint(-1, 1), BY - 3
    rx, ry = rng.uniform(5.5, 7.0), rng.uniform(3.0, 3.8)

    def color_at(x, y, edge):
        if edge:
            return BAG[0]
        wrinkle = (x + y * 2) % 5 == 0
        return BAG[3] if y < cy - 1 and not wrinkle else (BAG[1] if wrinkle else BAG[2])

    shape = ellipse(cell, cx, cy, rx, ry, color_at)
    top = min(y for _, y in shape)
    for hx in (round(cx - rx / 2), round(cx + rx / 2) - 1):
        cell.put(hx, top - 1, BAG[0])
        cell.put(hx + 1, top - 2, BAG[0])
        cell.put(hx + 2, top - 1, BAG[0])
    for (x, y) in sorted(shape):
        if y > cy + 1:
            cell.put(x, y, BAG[1][:3] + (110,))
    return None


def fishing_net(cell, variant):
    rng = cell.rng
    w, h = rng.randint(13, 16), rng.randint(6, 8)
    left, top = BX - w // 2, BY - 2 - h // 2
    mesh = set()
    for x in range(left, left + w):
        for y in range(top, top + h):
            u, v = x - left, y - top
            inside = ((u - w / 2) / (w / 2)) ** 2 + ((v - h / 2) / (h / 2)) ** 2 <= 1.0 + rng.uniform(-0.25, 0.1)
            if inside and ((u + v) % 3 == 0 or (u - v) % 3 == 0):
                mesh.add((x, y))
    for x, y in sorted(mesh):
        color = ROPE[2] if (x + y) % 2 else ROPE[1]
        cell.put(x, y, color if y <= BY - 2 else under(color, 150, 0.3))
    for x, y in sorted(mesh):
        if (x, y + 1) not in mesh and rng.random() < 0.3:
            cell.put(x, y + 1, ROPE[0])
    fx, fy = left + (2 if variant % 2 == 0 else w - 4), top
    for dx, dy, tone in ((0, 0, 2), (1, 0, 1), (0, 1, 1), (1, 1, 1), (-1, 0, 0), (2, 0, 0), (0, -1, 0), (1, -1, 0), (0, 2, 0), (1, 2, 0)):
        cell.put(fx + dx, fy + dy, NET_FLOAT[tone + (1 if tone else 0)] if tone else NET_FLOAT[0])
    cell.put(fx, fy, NET_FLOAT[3])
    ripple(cell, BX, BY - 1, w / 2 + 3, h / 2 + 1)
    return None


def tire(cell, variant):
    rng = cell.rng
    cx, cy = BX, BY - 3
    rx, ry = rng.uniform(6.5, 7.5), rng.uniform(3.4, 4.0)
    hole_rx, hole_ry = rx * 0.45, ry * 0.42

    def color_at(x, y, edge):
        if ((x + 0.5 - cx) / hole_rx) ** 2 + ((y + 0.5 - cy - 0.6) / hole_ry) ** 2 <= 1.0:
            return None
        if edge:
            return TIRE[0]
        if y < cy - 1:
            return TIRE[3] if (x + y) % 3 == 0 else TIRE[2]
        return TIRE[1] if (x % 2 == 0) else TIRE[2]

    ellipse(cell, cx, cy, rx, ry, color_at)
    sink(cell, cy, 160)
    foam_ring(cell, cx, cy + 1, rx + 1, ry * 0.6, 0.3, front_only=True)
    ripple(cell, cx, cy + 1, rx + 3, ry + 0.6)
    return None


def crate(cell, variant):
    rng = cell.rng
    w = rng.randint(10, 12)
    front_h = rng.randint(5, 6)
    top_h = 4
    left = BX - w // 2
    base = BY - 1
    for x in range(left, left + w):
        for y in range(base - front_h, base + 1):
            edge = x in (left, left + w - 1) or y in (base - front_h, base)
            plank = (y - (base - front_h)) % 3 == 0
            cell.put(x, y, CRATE[0] if edge else (CRATE[1] if plank else CRATE[2]))
        for k in range(top_h):
            y = base - front_h - 1 - k
            xs = x + (top_h - k) // 2
            edge = k == top_h - 1 or x in (left, left + w - 1)
            cell.put(xs, y, CRATE[0] if edge else (CRATE[4] if (x - left) % 4 == 1 else CRATE[3]))
    for y in range(base - front_h + 1, base):
        cell.put(left + w // 2, y, CRATE[1])
    waterline = base - front_h // 2
    sink(cell, waterline, 160)
    foam_ring(cell, BX, waterline + 1, w / 2 + 1.5, 1.8, 0.25, front_only=True)
    ripple(cell, BX, waterline + 1, w / 2 + 4, 3)
    return None


KINDS = [
    seagrass, kelp, algae_patch, sea_rock, sunken_rock, sea_stack, floating_weed,
    bottle, can, plastic_bag, fishing_net, tire, crate,
]


def rows():
    height = nature.CELL[1]
    image = Image.new("RGBA", (nature.CELL[0] * 4, height * len(KINDS)), (0, 0, 0, 0))
    for row, kind in enumerate(KINDS):
        for variant in range(4):
            cell = SeaCell(random.Random(f"{kind.__name__}:{variant}"))
            kind(cell, variant)
            image.paste(cell.image(), (variant * nature.CELL[0], row * height))
    return image


def main():
    file = art.path("decorations", "decorations.png")
    sheet = Image.open(file).convert("RGBA")
    art.put_rows(sheet, rows(), nature.CELL[1], FIRST_ROW).save(file)


if __name__ == "__main__":
    if "--preview" in sys.argv:
        rows().save(sys.argv[sys.argv.index("--preview") + 1])
    else:
        main()
    print("ok")
