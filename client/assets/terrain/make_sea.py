"""Desenha os tipos de decoração da água (.specs/sea-life/01-sea-art.md).

Uso: python -I make_sea.py   (precisa do Pillow; roda de dentro de assets/terrain)

Cada tipo é uma linha de decorations/decorations.png (51 a 63; a 55 e a 57, da pedra submersa
e da alga boiando que saíram, ficam vazias), com 4 variantes, no traço
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
    for _ in range(rng.randint(5, 8)):
        x0 = BX + rng.randint(-7, 7)
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

def stamp(cell, art, palette, left, bottom):
    """Desenha um desenho em texto (uma letra por pixel, '.' vazio) com o pé em `bottom`."""
    widths = {len(line) for line in art}
    assert len(widths) == 1, art
    top = bottom - len(art) + 1
    for row, line in enumerate(art):
        for column, letter in enumerate(line):
            if letter != '.':
                cell.put(left + column, top + row, palette[letter])
    return top


def float_in_water(cell, art, palette, sunk, flip=False, lift=0):
    """Põe o lixo boiando: as `sunk` linhas de baixo ficam embaixo d'água, com espuma e anel."""
    if flip:
        art = [line[::-1] for line in art]
    width = len(art[0])
    bottom = BY + sunk - 3 - lift
    stamp(cell, art, palette, BX - width // 2, bottom)
    waterline = bottom - sunk
    sink(cell, waterline, 170, 30)
    foam_ring(cell, BX, waterline + 1, width / 2 + 1, 1.6, 0.3, front_only=True)
    ripple(cell, BX, waterline + 1, width / 2 + 4, 2.8)


PET_BOTTLE = [
    "..oooooooooo....",
    ".ohhhrrrrhhhooo.",
    "owwwwsssswwwwwbo",
    "occccrrrrccccwbo",
    ".occcrrrrcccooo.",
    "..oooooooooo....",
]
PET_LABELS = [(206, 46, 46), (40, 150, 70), (40, 96, 200), (236, 150, 30)]
PET_CAPS = [(30, 90, 200), (220, 40, 40), (250, 250, 250), (40, 150, 70)]


def bottle(cell, variant):
    palette = {
        'o': (40, 72, 92), 'h': (240, 252, 255), 'w': (194, 230, 242), 'c': (142, 198, 218),
        'r': PET_LABELS[variant], 's': (250, 250, 250), 'b': PET_CAPS[variant],
    }
    float_in_water(cell, PET_BOTTLE, palette, 2, flip=variant % 2 == 1)
    return None


SODA_CAN = [
    ".oooooooooo.",
    "ollrrrrrrrmo",
    "oLlssrrrrrmo",
    "ollrrsssrrmo",
    "ollrrrrrssmo",
    ".oooooooooo.",
]
CAN_BODIES = [((196, 30, 36), (250, 250, 250)), ((34, 80, 170), (240, 210, 60)), ((30, 130, 60), (250, 250, 250)), ((40, 40, 44), (220, 40, 40))]


def can(cell, variant):
    body, stripe = CAN_BODIES[variant]
    palette = {
        'o': (30, 30, 36), 'l': (214, 218, 224), 'L': (120, 124, 132), 'm': (150, 154, 160),
        'r': body, 's': stripe,
    }
    float_in_water(cell, SODA_CAN, palette, 2, flip=variant >= 2)
    return None


SHOPPING_BAG = [
    ".ooo....ooo.",
    ".o.o....o.o.",
    ".o.o....o.o.",
    "owwwoooowwwo",
    "owhwwwwwwwwo",
    "owwwwfwwwwwo",
    "owwfwwLLwhwo",
    "owwwwwLLfwwo",
    "oggggggggggo",
    ".oooooooooo.",
]
BAG_TONES = [
    ((150, 160, 168), (246, 248, 250), (210, 216, 222), (222, 228, 232), (220, 50, 50)),
    ((60, 100, 150), (150, 196, 236), (110, 160, 210), (124, 172, 220), (250, 250, 250)),
    ((150, 130, 40), (250, 228, 110), (220, 196, 80), (232, 206, 90), (200, 40, 40)),
    ((150, 160, 168), (246, 248, 250), (210, 216, 222), (222, 228, 232), (40, 120, 200)),
]


def plastic_bag(cell, variant):
    outline, body, fold, shade, logo = BAG_TONES[variant]
    palette = {'o': outline, 'w': body, 'h': (255, 255, 255), 'f': fold, 'g': shade, 'L': logo}
    float_in_water(cell, SHOPPING_BAG, palette, 3, flip=variant % 2 == 1)
    return None


OLD_BOOT = [
    "oooooo.....",
    "odddddo....",
    "olkkkko....",
    "olkxkko....",
    "olkkxko....",
    "olkxkkoooo.",
    "olkkkklkkko",
    "olkkkkkkkko",
    "ossssssssso",
    ".ooooooooo.",
]
BOOT_TONES = [
    ((40, 24, 14), (150, 100, 60), (110, 70, 40), (222, 204, 156)),
    ((20, 20, 22), (92, 92, 98), (60, 60, 66), (200, 200, 200)),
    ((20, 44, 24), (96, 150, 84), (62, 112, 58), (62, 112, 58)),
    ((48, 28, 12), (178, 120, 64), (136, 88, 46), (240, 224, 180)),
]


def old_boot(cell, variant):
    outline, light, leather, lace = BOOT_TONES[variant]
    palette = {'o': outline, 'd': (22, 14, 8), 'l': light, 'k': leather, 'x': lace, 's': (52, 46, 42)}
    float_in_water(cell, OLD_BOOT, palette, 4, flip=variant % 2 == 1)
    return None


OLD_TIRE = [
    "....oooooooo....",
    "..oohhThhThhoo..",
    ".otTtoooooottTo.",
    "ottTo......oTtto",
    "otTto......ottTo",
    ".ottToooooootto.",
    "..oottTttTttoo..",
    "....oooooooo....",
]


def tire(cell, variant):
    palette = {'o': (10, 10, 12), 't': (40, 40, 46), 'T': (72, 72, 80), 'h': (96, 96, 104)}
    float_in_water(cell, OLD_TIRE, palette, 2, flip=variant % 2 == 1)
    return None


PLASTIC_JUG = [
    "..oooo....",
    "..obbo....",
    ".owwwwoooo",
    "owhwwwwo.o",
    "owhwwwwo.o",
    "owwwwwwooo",
    "owwwwwwwwo",
    "owwllllwwo",
    "owwllllwwo",
    "occcccccco",
    ".oooooooo.",
]
JUG_TONES = [
    ((236, 232, 214), (200, 194, 172), (220, 60, 40), (60, 120, 200)),
    ((246, 248, 250), (206, 212, 218), (40, 96, 200), (40, 150, 70)),
    ((150, 196, 236), (110, 160, 210), (250, 250, 250), (250, 250, 250)),
    ((240, 200, 80), (204, 164, 56), (40, 40, 44), (200, 40, 40)),
]


def jug(cell, variant):
    body, shade, cap, label = JUG_TONES[variant]
    palette = {'o': (90, 92, 96), 'w': body, 'h': (255, 255, 255), 'c': shade, 'b': cap, 'l': label}
    float_in_water(cell, PLASTIC_JUG, palette, 4, flip=variant % 2 == 1)
    return None


KINDS = [
    seagrass, kelp, algae_patch, sea_rock, None, sea_stack, None,
    bottle, can, plastic_bag, old_boot, tire, jug,
]


def rows():
    height = nature.CELL[1]
    image = Image.new("RGBA", (nature.CELL[0] * 4, height * len(KINDS)), (0, 0, 0, 0))
    for row, kind in enumerate(KINDS):
        if kind is None:
            continue
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
