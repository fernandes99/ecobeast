"""Desenha a arte do Vulcão e da lava (.specs/volcano/01-volcano-art.md).

Uso: python -I make_volcano.py [--preview saida.png]   (precisa do Pillow e do numpy)

Grava, só por código:
- surfaces/volcano.png, lshallow.png e ldeep.png, que se repetem sem emenda, e
  surfaces/volcano_cliff.png, o paredão de colunas de basalto;
- as linhas 10 (a borda do Vulcão), 11 (a crosta da lava) e 12 (a lava rasa avançando sobre a
  funda) de transitions/transitions.png;
- a linha 7 de transitions/drips.png (as lascas de basalto no alto do paredão);
- as linhas 72 a 78 de decorations/decorations.png, no traço do make_nature.py.
Rodar de novo regrava só essas linhas. Com --preview, grava só a prévia ampliada.

A chave de cor da lava (HOT_MIN_RED e HOT_MAX_BLUE) é a mesma do day_light.gdshader: só o
que é lava acesa cai nela, e o filtro da noite não a escurece.
"""

import math
import os
import random
import sys

import numpy as np
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.dont_write_bytecode = True
sys.path.insert(0, HERE)

import make_desert_snow as art  # noqa: E402
import make_glacier as glacier  # noqa: E402
import make_nature as nature  # noqa: E402

VOLCANO_ROW = 10
CRUST_ROW = 11
RIM_ROW = 12
DRIP_ROW = 7
FIRST_ROW = 72
SURFACE_SIZE = 512
BX, BY = nature.BASE

HOT_MIN_RED = 0.33
HOT_MAX_BLUE = 0.06

BASALT = [(40, 36, 38), (50, 45, 46), (60, 54, 54), (71, 64, 62), (84, 76, 72)]
ASH = (122, 114, 110)
PIT = (20, 18, 20)
EMBER = (126, 46, 32)
EDGE = [(28, 25, 27), (48, 43, 44), (74, 68, 66), (104, 98, 94), (138, 132, 126)]
CRUST = [(24, 18, 18), (40, 28, 26), (60, 38, 32), (84, 50, 38)]
SHALLOW = [(232, 78, 8), (240, 110, 10), (248, 146, 12), (253, 184, 12), (255, 222, 14)]
GLOW = (255, 244, 120)
DEEP = [(112, 24, 8), (136, 32, 10), (160, 42, 10), (186, 54, 12), (210, 68, 12)]
DEEP_VEIN = [(236, 86, 10), (248, 132, 12)]
ROCK = [(16, 14, 16), (34, 30, 32), (52, 46, 47), (70, 62, 61), (90, 80, 76), (112, 102, 96)]
CHAR = [(14, 12, 12), (30, 26, 25), (48, 42, 40), (70, 62, 58)]
OBSIDIAN = [(10, 8, 14), (24, 18, 32), (44, 32, 60), (86, 62, 120), (170, 150, 210)]
SMOKE = [(214, 210, 204), (186, 182, 178), (156, 152, 150)]
SULFUR = (214, 200, 96)
LAVA_HOT = [(250, 120, 10), (255, 176, 12), (255, 226, 14)]


def is_hot(color):
    return color[0] / 255.0 >= HOT_MIN_RED and color[2] / 255.0 <= HOT_MAX_BLUE


# O chão ------------------------------------------------------------------------------------


def quantized(value, palette):
    low, high = np.percentile(value, 2), np.percentile(value, 98)
    value = np.clip((value - low) / (high - low), 0.0, 0.999)
    levels = len(palette)
    scaled = value * levels
    index = scaled.astype(int)
    bayer = np.tile(np.array(nature.BAYER), (SURFACE_SIZE // 2, SURFACE_SIZE // 2))
    index = np.minimum(index + (scaled - index > bayer), levels - 1)
    return Image.fromarray(np.array(palette, dtype=np.uint8)[index], "RGB")


def fbm(rng):
    noise = glacier.periodic_noise
    return 0.5 * noise(rng, 4, 4) + 0.25 * noise(rng, 8, 8) + 0.15 * noise(rng, 16, 16) + 0.1 * noise(rng, 32, 32)


PLATE = [(42, 38, 41), (51, 46, 48), (61, 55, 56), (72, 65, 65), (84, 76, 74)]
PLATE_RIM = (106, 97, 93)
PLATE_SHADOW = (36, 32, 35)
CRACK = (22, 19, 21)
PORE_LIGHT = (84, 77, 75)
PLATES = 58


def plate_field(rng):
    """As placas de basalto: a célula de Voronoi de cada pixel, numa grade que se repete, com a
    borda torta por um ruído. Devolve o dono de cada pixel e a distância até a borda."""
    size = SURFACE_SIZE
    seeds = rng.random((PLATES, 2)) * size
    ys, xs = np.mgrid[0:size, 0:size].astype(np.float64)
    warp = 5.0
    xs = xs + (glacier.periodic_noise(rng, 16, 16) - 0.5) * 2 * warp
    ys = ys + (glacier.periodic_noise(rng, 16, 16) - 0.5) * 2 * warp
    first = np.full((size, size), np.inf)
    second = np.full((size, size), np.inf)
    owner = np.zeros((size, size), dtype=int)
    for index, (sx, sy) in enumerate(seeds):
        for ox in (-size, 0, size):
            for oy in (-size, 0, size):
                d = np.hypot(xs - sx - ox, (ys - sy - oy) * 1.35)
                closer = d < first
                second = np.where(closer, first, np.minimum(second, d))
                first = np.where(closer, d, first)
                owner = np.where(closer, index, owner)
    return owner, second - first


def volcano_surface():
    rng = np.random.default_rng(1313)
    owner, gap = plate_field(rng)
    mottle = 0.6 * glacier.periodic_noise(rng, 8, 8) + 0.4 * glacier.periodic_noise(rng, 24, 24)
    shade = rng.integers(0, 2, PLATES)[owner]
    value = np.clip((mottle - mottle.min()) / (mottle.max() - mottle.min()), 0, 0.999)
    scaled = value * 4
    index = scaled.astype(int)
    bayer = np.tile(np.array(nature.BAYER), (SURFACE_SIZE // 2, SURFACE_SIZE // 2))
    index = np.minimum(index + (scaled - index > bayer), 3) + shade
    index = np.minimum(index, len(PLATE) - 1)
    color = np.array(PLATE, dtype=np.uint8)[index]
    crack = gap < 1.6
    above = np.roll(crack, 1, axis=0)
    below = np.roll(crack, -1, axis=0)
    left = np.roll(crack, 1, axis=1)
    color[~crack & (above | left)] = PLATE_RIM
    color[~crack & (below | np.roll(crack, -1, axis=1)) & ~(above | left)] = PLATE_SHADOW
    color[crack] = CRACK
    image = Image.fromarray(color, "RGB")
    pixels = image.load()
    pick = random.Random("volcano-surface")
    inside = ~crack & ~above & ~below & ~left & (gap > 4)

    def free(x, y):
        return inside[y % SURFACE_SIZE, x % SURFACE_SIZE]

    for _ in range(420):
        x, y = pick.randrange(SURFACE_SIZE), pick.randrange(SURFACE_SIZE)
        if free(x, y) and free(x + 1, y) and free(x, y + 1):
            pixels[x, y] = CRACK
            if pick.random() < 0.5:
                pixels[(x + 1) % SURFACE_SIZE, y] = CRACK
            pixels[x, (y + 1) % SURFACE_SIZE] = PORE_LIGHT
    for _ in range(260):
        x, y = pick.randrange(SURFACE_SIZE), pick.randrange(SURFACE_SIZE)
        if free(x, y):
            pixels[x, y] = ASH
    for _ in range(34):
        x, y = pick.uniform(0, SURFACE_SIZE), pick.uniform(0, SURFACE_SIZE)
        angle = pick.uniform(0, math.tau)
        for _step in range(pick.randint(5, 14)):
            px, py = round(x) % SURFACE_SIZE, round(y) % SURFACE_SIZE
            if not free(px, py):
                break
            pixels[px, py] = PLATE_SHADOW
            pixels[px, (py + 1) % SURFACE_SIZE] = PLATE[3]
            x += math.cos(angle)
            y += math.sin(angle) * 0.6
            angle += pick.uniform(-0.6, 0.6)
    for _ in range(30):
        x, y = pick.randrange(SURFACE_SIZE), pick.randrange(SURFACE_SIZE)
        if crack[y, x]:
            pixels[x, y] = EMBER
    return image


def lava_surface(deep):
    rng = np.random.default_rng(1414 if deep else 1515)
    flow = glacier.periodic_noise(rng, 3, 14)
    value = 0.55 * fbm(rng) + 0.45 * flow
    image = quantized(value, DEEP if deep else SHALLOW)
    pixels = image.load()
    pick = random.Random("ldeep" if deep else "lshallow")

    def put(x, y, color):
        pixels[x % SURFACE_SIZE, y % SURFACE_SIZE] = color

    def vein(x, y, angle, length, colors):
        for step in range(length):
            put(round(x), round(y), colors[1] if step % 5 else colors[0])
            if not deep and step % 3 == 0:
                put(round(x), round(y) + 1, colors[0])
            x += math.cos(angle)
            y += math.sin(angle) * 0.5
            angle += pick.uniform(-0.2, 0.2)

    veins = DEEP_VEIN if deep else [SHALLOW[4], LAVA_HOT[2]]
    for _ in range(46 if deep else 30):
        angle = pick.uniform(-0.4, 0.4) + (math.pi if pick.random() < 0.5 else 0.0)
        vein(pick.uniform(0, SURFACE_SIZE), pick.uniform(0, SURFACE_SIZE), angle, pick.randint(16, 60), veins)
    for _ in range(120 if deep else 60):
        x, y = pick.randrange(SURFACE_SIZE), pick.randrange(SURFACE_SIZE)
        put(x, y, DEEP_VEIN[1] if deep else SHALLOW[4])
        put(x + 1, y, DEEP_VEIN[0] if deep else SHALLOW[3])
    if not deep:
        for _ in range(50):
            x, y = pick.randrange(SURFACE_SIZE), pick.randrange(SURFACE_SIZE)
            for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1), (2, 0)):
                put(x + dx, y + dy, SHALLOW[0])
    return image


COLUMN_TONES = [(46, 42, 45), (53, 48, 50), (60, 54, 56)]
COLUMN_LIGHT = (74, 67, 67)
COLUMN_RIM = (98, 90, 87)
COLUMN_SHADOW = (36, 32, 35)
COLUMN_JOINT = (20, 18, 20)
FACE_SIZE = (512, 64)
FACE_BAND = 32


def volcano_cliff():
    """O paredão do Vulcão: colunas de basalto em pé, com a borda clara à esquerda, a sombra à
    direita e as juntas que as partem em blocos. A metade de baixo se repete nos paredões
    altos (HexMapView.face_segments), então as juntas dela fecham a volta de 32 px."""
    width, height = FACE_SIZE
    pick = random.Random("volcano-cliff")
    image = Image.new("RGB", FACE_SIZE, COLUMN_JOINT)
    pixels = image.load()
    edges = []
    x = 0
    while x < width - 7:
        step = pick.randint(8, 16)
        if width - (x + step) < 8:
            step = width - x
        edges.append((x, x + step))
        x += step
    for left, right in edges:
        tone = pick.choice(COLUMN_TONES)
        crest = pick.randint(1, 4)
        joints = sorted(pick.sample(range(FACE_BAND, height), pick.randint(1, 2)))
        top_joints = [y for y in (pick.randint(8, 26),) if pick.random() < 0.8]
        cuts = set(top_joints + joints)
        split = left + pick.randint(3, right - left - 4) if right - left >= 12 and pick.random() < 0.4 else None
        for y in range(height):
            for k, px in enumerate(range(left, right - 1)):
                if y < crest:
                    color = COLUMN_JOINT if y == 0 else COLUMN_RIM
                elif y in cuts:
                    color = COLUMN_JOINT
                elif px == split and y > crest + 2:
                    color = COLUMN_SHADOW
                elif y - 1 in cuts or y == crest:
                    color = COLUMN_RIM if k > 0 else COLUMN_LIGHT
                elif k == 0:
                    color = COLUMN_RIM
                elif k == 1:
                    color = COLUMN_LIGHT
                elif px == right - 2:
                    color = COLUMN_SHADOW
                else:
                    color = tone
                pixels[px % width, y] = color
    for _ in range(500):
        x, y = pick.randrange(width), pick.randrange(4, height)
        if pixels[x, y] in COLUMN_TONES:
            pixels[x, y] = COLUMN_SHADOW if pick.random() < 0.7 else COLUMN_LIGHT
    return image


# Os arremates e o escorrido ---------------------------------------------------------------------


def transition_rows():
    sheet = Image.open(art.path("transitions", "transitions.png")).convert("RGBA")
    height = art.TRANSITION_CELL[1] * art.TRANSITION_VARIANTS
    stone = art.sheet_rows(sheet, height, 4, 1)
    rows = Image.new("RGBA", (sheet.width, height * 3), (0, 0, 0, 0))
    rows.paste(art.recolor(stone, EDGE), (0, 0))
    rows.paste(art.recolor(stone, CRUST), (0, height))
    rows.paste(art.recolor(stone, SHALLOW[1:]), (0, height * 2))
    return rows


def drip_rows():
    width = 32
    rows = Image.new("RGBA", (width * 4, art.DRIP_CELL_HEIGHT * 2), (0, 0, 0, 0))
    pixels = rows.load()
    for long in (0, 1):
        top = long * art.DRIP_CELL_HEIGHT
        for variant in range(4):
            rng = random.Random(f"basalt:{long}:{variant}")
            left = variant * width
            for x in range(width):
                pixels[left + x, top] = EDGE[3] + (255,)
                pixels[left + x, top + 1] = EDGE[1] + (255,)
            x = rng.randint(0, 4)
            while x < width:
                size = rng.choice([2, 3, 3, 4])
                length = rng.randint(2, 4) if not long else rng.randint(3, 9)
                for k in range(length):
                    w = max(1, round(size * (1 - k / (length + 1))))
                    for dx in range(w):
                        if x + dx >= width:
                            continue
                        color = EDGE[0] if k == length - 1 or dx == w - 1 else (EDGE[3] if dx == 0 else EDGE[2])
                        pixels[left + x + dx, top + 2 + k] = color + (255,)
                x += size + rng.randint(2, 6)
    return rows


# As decorações ----------------------------------------------------------------------------------


def polygon(cx, cy, radius, sides, rng, squash=0.6, jitter=0.3):
    corners = []
    for k in range(sides):
        a = (k + rng.uniform(-jitter, jitter)) / sides * math.tau
        r = radius * rng.uniform(0.7, 1.05)
        corners.append((cx + math.cos(a) * r, cy + math.sin(a) * r * squash))
    mask = Image.new("1", nature.CELL, 0)
    ImageDraw.Draw(mask).polygon(corners, fill=1)
    return {(x, y) for y in range(nature.CELL[1]) for x in range(nature.CELL[0]) if mask.getpixel((x, y))}


def lump(cell, shape, palette, height=2):
    """Uma pedra angulosa: o topo pela luz de cima à esquerda, a frente mais escura e o contorno."""
    side = {(x, y + k) for x, y in shape for k in range(1, height + 1) if (x, y + k) not in shape}
    solid = shape | side
    for x, y in solid:
        edge = any((x + dx, y + dy) not in solid for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if edge:
            cell.put(x, y, palette[0])
        elif (x, y) in side:
            cell.put(x, y, palette[1])
        else:
            lit = (x - 1, y) not in shape or (x, y - 1) not in shape
            dark = (x + 1, y) not in shape or (x, y + 1) not in shape
            cell.put(x, y, palette[-1] if lit else (palette[2] if dark else palette[3]))
    return solid


def basalt_pebbles(cell, variant):
    rng = cell.rng
    count = [3, 4, 5, 3][variant]
    for _ in range(count):
        shape = polygon(BX + rng.uniform(-9, 9), BY - 4 + rng.uniform(-4, 2), rng.uniform(2.2, 3.8), rng.randint(4, 6), rng)
        lump(cell, shape, ROCK[:5], 1)
    return (8, 2)


FISSURE_WALL = (150, 46, 20)
FISSURE_LIP = [(24, 18, 18), (40, 28, 26), (66, 46, 40), (100, 90, 86)]


def fissure_shape(rng, variant):
    """A fenda: o miolo de lava (com a distância até a borda) e a crosta em volta."""
    length = [40, 36, 30, 42][variant]
    widest = [9.0, 7.0, 12.0, 6.5][variant]
    left = BX - length // 2
    cy = BY - 9.0
    slope = rng.uniform(-0.25, 0.25)
    core = set()
    for i in range(length):
        t = (i + 0.5) / length
        if i % 6 == 0:
            slope = max(-0.45, min(0.45, slope + rng.uniform(-0.35, 0.35)))
        cy += slope
        if variant == 3:
            cy = BY - 9.0 + 3.5 * math.sin(t * math.pi * 1.6)
        half = widest / 2 * math.sin(math.pi * t) ** 0.55 * rng.uniform(0.85, 1.1)
        half_y = max(0.6, half * 0.7)
        for y in range(round(cy - half_y), round(cy + half_y) + 1):
            core.add((left + i, y))
    if variant == 1:
        x, y = BX + 2.0, BY - 9.0
        for k in range(14):
            half = 2.6 * (1 - k / 14) + 0.6
            for yy in range(round(y - half * 0.7), round(y + half * 0.7) + 1):
                core.add((round(x), yy))
                core.add((round(x) + 1, yy))
            x += 0.9
            y -= 0.75
    distance = {}
    frontier = [spot for spot in core if any((spot[0] + dx, spot[1] + dy) not in core for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for spot in frontier:
        distance[spot] = 1
    step = 1
    while frontier:
        step += 1
        grown = []
        for x, y in frontier:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                spot = (x + dx, y + dy)
                if spot in core and spot not in distance:
                    distance[spot] = step
                    grown.append(spot)
        frontier = grown
    near = {(x + dx, y + dy) for x, y in core for dx in (-1, 0, 1) for dy in (-1, 0, 1)} - core
    lip = near | {(x + dx, y + dy) for x, y in near for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))} - core
    return distance, near, lip


def lava_crack(cell, variant):
    rng = cell.rng
    distance, near, lip = fissure_shape(rng, variant)
    for x, y in lip:
        if (x, y) in near:
            above = (x, y + 1) in distance or (x, y + 2) in distance
            cell.put(x, y, FISSURE_LIP[3] if above else FISSURE_LIP[1])
        else:
            cell.put(x, y, FISSURE_LIP[0] if (x, y - 1) not in near else FISSURE_LIP[2])
    tones = [DEEP[3], SHALLOW[0], SHALLOW[1], SHALLOW[2], SHALLOW[3], SHALLOW[4]]
    for (x, y), d in distance.items():
        if (x, y - 1) not in distance:
            cell.put(x, y, FISSURE_WALL)
            continue
        level = min(d - 1 + (1 if nature.BAYER[y % 2][x % 2] < 0.5 else 0), len(tones) - 1)
        cell.put(x, y, tones[level])
    inner = sorted(spot for spot, d in distance.items() if d >= 3)
    for _ in range(min(len(inner), rng.randint(3, 6))):
        cell.put(*rng.choice(inner), LAVA_HOT[2])
    return None


def fissure_blocks():
    """A linha fechada de cada variante da fenda, em pixels a partir do pé (BX, BY), pela borda
    de cima e a de baixo da crosta, de 5 em 5 pixels."""
    blocks = []
    for variant in range(4):
        distance, near, lip = fissure_shape(random.Random(f"lava_crack:{variant}"), variant)
        solid = set(distance) | lip
        xs = sorted({x for x, _ in solid})
        columns = list(range(xs[0], xs[-1] + 1, 5))
        if columns[-1] != xs[-1]:
            columns.append(xs[-1])
        top = [(x, min(y for xx, y in solid if xx == x)) for x in columns]
        bottom = [(x, max(y for xx, y in solid if xx == x) + 1) for x in reversed(columns)]
        points = []
        for x, y in top + bottom:
            points += [x - BX, y - BY]
        blocks.append(points)
    return blocks


def fumarole(cell, variant):
    rng = cell.rng
    cy = BY - 4
    ring = polygon(BX, cy, 7.5, 9, rng, squash=0.5, jitter=0.15)
    hole = polygon(BX, cy - 0.5, 4.0, 8, rng, squash=0.5, jitter=0.1)
    lump(cell, ring - hole, ROCK[:5], 2)
    for x, y in hole:
        cell.put(x, y, PIT if (x, y - 1) in hole else ROCK[1])
    for x, y in sorted(ring - hole):
        if (x, y + 1) in hole and rng.random() < 0.35:
            cell.put(x, y, SULFUR)
    x, y = float(BX), float(cy - 2)
    drift = rng.choice([-1, 1]) * rng.uniform(0.15, 0.35)
    height = [26, 34, 22, 30][variant]
    for step in range(height):
        t = step / height
        width = 1 + round(2.5 * math.sin(math.pi * min(1.0, t * 1.4)))
        wobble = math.sin(step * 0.45 + variant) * 1.4
        for k in range(-width // 2, width - width // 2):
            alpha = round(170 * (1 - t) + 40)
            tone = SMOKE[0] if k < 0 else (SMOKE[1] if k == 0 else SMOKE[2])
            if rng.random() < 0.85 - t * 0.5:
                cell.put(round(x + wobble + k), round(y), tone + (alpha,))
        x += drift
        y -= 1
    return None


def burnt_tree(cell, variant):
    rng = cell.rng
    top = [BY - 34, BY - 42, BY - 28, BY - 38][variant]
    nature.trunk(cell, BX - 1, top, BY - 1, 3, CHAR)
    for _ in range(rng.randint(3, 5)):
        y = rng.randint(top + 2, BY - 12)
        side = rng.choice([-1, 1])
        length = rng.randint(4, 9)
        nature.line(cell, BX + (2 if side > 0 else -1), y, BX + side * length, y - rng.randint(2, 7), CHAR[1])
    for k in range(rng.randint(2, 3)):
        nature.line(cell, BX, top, BX + rng.randint(-4, 4), top - rng.randint(3, 6), CHAR[0])
    for x in range(BX - 4, BX + 5):
        cell.put(x, BY, CHAR[0])
    if variant == 3:
        cell.put(BX - 1, BY - 2, LAVA_HOT[0])
        cell.put(BX, BY - 3, LAVA_HOT[1])
    return (6, 2)


def ash_patch(cell, variant):
    rng = cell.rng
    blobs = [(BX + rng.uniform(-6, 6), BY - 5 + rng.uniform(-2, 2), rng.uniform(4, 8)) for _ in range(rng.randint(2, 4))]
    tones = [(150, 144, 140, 170), (176, 170, 166, 180), (198, 194, 190, 190)]
    for y in range(BY - 14, BY + 1):
        for x in range(nature.CELL[0]):
            inside = max((1 - math.hypot(x + 0.5 - cx, (y + 0.5 - cy) / 0.55) / r) for cx, cy, r in blobs)
            if inside <= 0:
                continue
            if inside < 0.3 and nature.BAYER[y % 2][x % 2] > inside * 2.5:
                continue
            cell.put(x, y, tones[0] if inside < 0.4 else (tones[1] if inside < 0.75 else tones[2]))
    for _ in range(rng.randint(3, 6)):
        cell.put(BX + rng.randint(-8, 8), BY - 5 + rng.randint(-3, 2), (110, 104, 100, 200))
    return None


def obsidian(cell, variant):
    rng = cell.rng
    pieces = [[(0, 0, 5.5)], [(-3, 0, 4.5), (4, 1, 3.0)], [(0, 0, 4.0)], [(-4, 1, 3.5), (2, -1, 5.0), (6, 2, 2.5)]][variant]
    for dx, dy, r in pieces:
        corners = []
        cx, cy = BX + dx, BY - 4 + dy
        for k in range(rng.randint(4, 5)):
            a = k / 4.5 * math.tau + rng.uniform(-0.4, 0.4)
            rr = r * (1.6 if k == 0 else rng.uniform(0.6, 1.0))
            corners.append((cx + math.cos(a - math.pi / 2) * rr * 0.7, cy + math.sin(a - math.pi / 2) * rr))
        mask = Image.new("1", nature.CELL, 0)
        ImageDraw.Draw(mask).polygon(corners, fill=1)
        shape = {(x, y) for y in range(nature.CELL[1]) for x in range(nature.CELL[0]) if mask.getpixel((x, y))}
        for x, y in shape:
            edge = any((x + ex, y + ey) not in shape for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if edge:
                cell.put(x, y, OBSIDIAN[0])
            elif (x - 1, y) not in shape or (x, y - 1) not in shape:
                cell.put(x, y, OBSIDIAN[3])
            elif (x + y) % 5 == 0:
                cell.put(x, y, OBSIDIAN[2])
            else:
                cell.put(x, y, OBSIDIAN[1])
        top = min(shape, key=lambda p: (p[1], p[0]))
        cell.put(top[0], top[1] + 1, OBSIDIAN[4])
        cell.put(top[0], top[1] + 2, OBSIDIAN[3])
    return (5, 1)


def lava_crust(cell, variant):
    rng = cell.rng
    plates = [[(0, 0, 10.0)], [(-5, 0, 6.5), (6, -2, 5.0)], [(0, 0, 7.5)], [(-7, 1, 4.5), (3, -2, 6.0), (8, 3, 3.5)]][variant]
    for dx, dy, r in plates:
        shape = polygon(BX + dx, BY - 6 + dy, r, rng.randint(6, 8), rng, squash=0.42)
        for x, y in sorted(shape):
            for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                spot = (x + ex, y + ey)
                if spot not in shape and spot not in cell.pixels:
                    cell.put(*spot, LAVA_HOT[2])
        for x, y in shape:
            edge = any((x + ex, y + ey) not in shape for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            lit = (x - 1, y) not in shape or (x, y - 1) not in shape
            cell.put(x, y, CRUST[0] if edge else (CRUST[3] if lit else CRUST[rng.choice([1, 2, 2])]))
        inside = sorted(spot for spot in shape if cell.pixels[spot] not in (CRUST[0],))
        if len(inside) > 10:
            x, y = rng.choice(inside)
            for _ in range(rng.randint(3, round(r))):
                if (x, y) in shape:
                    cell.put(x, y, LAVA_HOT[0])
                x += rng.choice([-1, 1])
                y += rng.choice([-1, 0, 0, 1])
    return None


KINDS = [
    ("basalt_pebbles", "Pedrinhas de basalto", basalt_pebbles),
    ("lava_crack", "Rachadura de lava", lava_crack),
    ("fumarole", "Fumarola", fumarole),
    ("burnt_tree", "Árvore queimada", burnt_tree),
    ("ash_patch", "Cinza", ash_patch),
    ("obsidian", "Obsidiana", obsidian),
    ("lava_crust", "Crosta de lava", lava_crust),
]


def decoration_rows():
    rows = Image.new("RGBA", (nature.CELL[0] * 4, nature.CELL[1] * len(KINDS)), (0, 0, 0, 0))
    for row, (slug, _name, kind) in enumerate(KINDS):
        for variant in range(4):
            cell = glacier.FreeCell(random.Random(f"{slug}:{variant}"))
            shadow = kind(cell, variant)
            rows.paste(cell.image(shadow), (variant * nature.CELL[0], row * nature.CELL[1]))
    return rows


# A prévia ---------------------------------------------------------------------------------------

HEX = glacier.HEX
NEIGHBORS = glacier.NEIGHBORS
LOWER = glacier.LOWER
LAVA = ("lshallow", "ldeep")
SURFACE_ORDER = ["beach", "desert", "temperate", "boreal", "hill", "glacier", "snow", "stone", "mountain", "volcano"]
MATERIAL_ROWS = {"foam": 0, "temperate": 1, "boreal": 2, "mountain": 5, "volcano": VOLCANO_ROW, "lava_crust": CRUST_ROW, "lshallow": RIM_ROW}
DRIP_ROWS = {"temperate": 0, "boreal": 1, "volcano": DRIP_ROW}
CLIFF = ["stone", "mountain", "glacier", "volcano"]
DECORATION_ROWS = {"tree": 0, "pine": 1, "bush": 5, "tuft": 8, "flowers": 10, "boulder": 14, "rock_pile": 15, "spire": 16}
RADIUS = {
    "tree": 12, "pine": 12, "bush": 10, "tuft": 4, "flowers": 6, "boulder": 14, "rock_pile": 12, "spire": 13,
    "basalt_pebbles": 7, "lava_crack": 18, "fumarole": 7, "burnt_tree": 9, "ash_patch": 8, "obsidian": 6, "lava_crust": 9,
}
PREVIEW_PROPS = [["lava_crack", 0.14, 1, 1]]
RECIPES = {
    "temperate": [["tree", 0.3, 1, 2], ["bush", 0.3, 1, 2], ["tuft", 0.5, 1, 3], ["flowers", 0.2, 1, 2]],
    "boreal": [["pine", 0.6, 1, 3], ["bush", 0.2, 1, 1], ["tuft", 0.3, 1, 2]],
    "mountain": [["boulder", 0.3, 1, 1], ["rock_pile", 0.3, 1, 1], ["spire", 0.2, 1, 1]],
    "volcano": [["basalt_pebbles", 0.4, 1, 2], ["fumarole", 0.1, 1, 1], ["ash_patch", 0.3, 1, 1], ["burnt_tree", 0.06, 1, 1], ["obsidian", 0.06, 1, 1]],
    "lshallow": [["lava_crust", 0.35, 1, 2]],
}
NIGHT = (0.42, 0.48, 0.72)
NIGHT_SATURATION = 0.65
GLOW_RADIUS = 40
GLOW_COLOR = (1.0, 0.55, 0.2)
GLOW_STRENGTH = 1.0
GLOW_EMISSION = 0.35


def preview_map():
    """Um mapa de 14 por 10: Planície, Boreal e Montanha à esquerda, o Vulcão no resto, com as
    3 linhas de cima no nível 9 (o paredão aparece) e um lago de lava no meio, no nível 5, um
    abaixo do chão em volta, como a água."""
    tiles = {}
    center = (9, 6)
    cq = center[0] - center[1] // 2
    for r in range(10):
        for c in range(14):
            q = c - r // 2
            d = (abs(q - cq) + abs(r - center[1]) + abs(q - cq + r - center[1])) // 2
            if c <= 1:
                biome, height = ("temperate" if r < 4 else ("boreal" if r < 7 else "mountain")), (4 if r < 7 else 8)
            elif r <= 2:
                biome, height = "volcano", 9
            else:
                biome, height = "volcano", 6
                if d <= 1:
                    biome, height = "ldeep", 5
                elif d <= 2:
                    biome, height = "lshallow", 5
            if c == 2 and r > 2:
                height = 4 if r < 7 else 6
            tiles[(q, r)] = (biome, height)
    return tiles


def render(tiles, surfaces, faces, transitions, drips, sheet, rows_of):
    width = 14 * 64 + 32 + 40
    height = 9 * 42 + 58 + 60
    lift = 80
    canvas = Image.new("RGBA", (width, height + lift), (24, 30, 40, 255))
    hex_mask = Image.new("L", (65, 59), 0)
    ImageDraw.Draw(hex_mask).polygon(HEX, fill=255)
    rise = lambda level: level * 8

    def origin(q, r):
        return 64 * q + 32 * r + 8, 42 * r + lift

    def tint(biome, level):
        return 1.0 if biome in LAVA or biome.startswith("w") else 1.0 - 0.03 * max(5 - level, 0)

    def shaded(image, factor):
        if factor >= 0.999:
            return image
        r, g, b, a = image.split()
        r, g, b = (channel.point(lambda v: round(v * factor)) for channel in (r, g, b))
        return Image.merge("RGBA", (r, g, b, a))

    picked = random.Random("preview")
    glows = []
    for r in range(10):
        row_tiles = sorted((q, rr) for q, rr in tiles if rr == r)
        decorations = []
        for q, _ in row_tiles:
            biome, level = tiles[(q, r)]
            ox, oy = origin(q, r)
            oy -= rise(level)
            for (dq, dr), (a, b), face_shade in LOWER:
                neighbor = tiles.get((q + dq, r + dr))
                face = rise(level) - (rise(neighbor[1]) if neighbor else rise(level) - 0)
                if face <= 0:
                    continue
                texture = faces["volcano_cliff" if biome == "volcano" or biome in LAVA else ("cliff" if biome in CLIFF else "side")]
                (x0, y0), (x1, y1) = HEX[a], HEX[b]
                left, right = min(x0, x1), max(x0, x1)
                drip = DRIP_ROWS.get(biome)
                variant = picked.randrange(4)
                for x in range(left, right):
                    top = y0 + (y1 - y0) * (x - x0) / (x1 - x0)
                    for k in range(face):
                        ty = k if k < 64 else 32 + (k - 64) % 32
                        color = texture.getpixel(((ox + x) % texture.width, ty))
                        f = face_shade * tint(biome, level)
                        canvas.putpixel((ox + x, math.floor(oy + top + 0.5) + k), tuple(round(c * f) for c in color[:3]) + (255,))
                    if drip is not None:
                        row = drip * 2 + (1 if face >= 16 else 0)
                        for k in range(min(face, 16)):
                            color = drips.getpixel((variant * 32 + (x - left), row * 16 + k))
                            if color[3]:
                                f = face_shade * tint(biome, level)
                                canvas.putpixel((ox + x, math.floor(oy + top + 0.5) + k), tuple(round(c * f) for c in color[:3]) + (255,))
            source = surfaces[biome]
            gx, gy = origin(q, r)
            tile_image = Image.new("RGBA", (65, 59))
            for y in range(59):
                for x in range(65):
                    tile_image.putpixel((x, y), source.getpixel(((gx + x) % 512, (gy - lift + y) % 512)))
            canvas.paste(shaded(tile_image, tint(biome, level)), (ox, oy), hex_mask)
            rank = SURFACE_ORDER.index(biome) if biome in SURFACE_ORDER else -1
            for edge, (dq, dr) in enumerate(NEIGHBORS):
                neighbor = tiles.get((q + dq, r + dr))
                if neighbor is None:
                    continue
                neighbor_rank = SURFACE_ORDER.index(neighbor[0]) if neighbor[0] in SURFACE_ORDER else -1
                rim = biome == "ldeep" and neighbor[0] == "lshallow"
                if neighbor_rank <= rank and not rim:
                    continue
                if (dq, dr) in ((-1, 1), (0, 1)) and neighbor[1] > level:
                    continue
                material = "lshallow" if rim else "lava_crust" if biome in LAVA else ("foam" if biome.startswith("w") else neighbor[0])
                if material not in MATERIAL_ROWS:
                    continue
                row = MATERIAL_ROWS[material] * 3 + picked.randrange(3)
                cell = transitions.crop((edge * 64, row * 58, edge * 64 + 64, row * 58 + 58))
                canvas.alpha_composite(shaded(cell, tint(biome, level)), (ox, oy))
            if biome in LAVA and any(tiles.get((q + dq, r + dr), ("x", 0))[0] not in LAVA for dq, dr in NEIGHBORS):
                glows.append((ox + 32, oy + 29))
            placed = []
            recipe = RECIPES.get(biome, []) + (PREVIEW_PROPS if biome == "volcano" else [])
            for kind, chance, low, high in recipe:
                if picked.random() >= chance:
                    continue
                for _ in range(picked.randint(low, high)):
                    for _try in range(8):
                        spot = (picked.randint(-24, 24), picked.randint(-20, 20))
                        free = abs(spot[0]) / 2 + abs(spot[1]) <= 22 and math.hypot(*spot) >= RADIUS[kind]
                        free = free and all(math.hypot(spot[0] - s[0], spot[1] - s[1]) >= max(RADIUS[kind], RADIUS[k]) for k, s in placed)
                        if free:
                            placed.append((kind, spot))
                            break
            for kind, spot in placed:
                decorations.append((oy + 29 + spot[1], ox + 32 + spot[0], kind, picked.randrange(4), picked.random() < 0.5))
        for base_y, base_x, kind, variant, flipped in sorted(decorations):
            row = rows_of[kind]
            cell = sheet.crop((variant * 48, row * 64, variant * 48 + 48, row * 64 + 64))
            if flipped:
                cell = cell.transpose(Image.FLIP_LEFT_RIGHT)
            canvas.alpha_composite(cell, (base_x - 24, base_y - 60))
    return canvas, glows


def night(canvas, glows):
    """O filtro da noite como no day_light.gdshader: a cor da hora, menos na chave da lava, e a
    luz laranja em degraus em volta das bordas do lago."""
    source = np.asarray(canvas.convert("RGB"), dtype=np.float64) / 255.0
    hot = (source[..., 0] >= HOT_MIN_RED) & (source[..., 2] <= HOT_MAX_BLUE)
    gray = source @ np.array([0.299, 0.587, 0.114])
    color = gray[..., None] + (source - gray[..., None]) * NIGHT_SATURATION
    light = np.broadcast_to(np.array(NIGHT), source.shape).copy()
    glow = np.zeros_like(source)
    ys, xs = np.mgrid[0:source.shape[0], 0:source.shape[1]]
    for gx, gy in glows:
        t = 1.0 - np.hypot(xs + 0.5 - gx, ys + 0.5 - gy) / GLOW_RADIUS
        t = np.where(t > 0, (np.ceil(t * 4) / 4) ** 2, 0.0)
        lit = t[..., None] * np.array(GLOW_COLOR) * GLOW_STRENGTH
        light += lit
        glow += lit * GLOW_EMISSION
    light = np.minimum(light, 1.0)
    light[hot] = 1.0
    color[hot] = source[hot]
    result = np.clip(color * light + glow, 0.0, 1.0)
    result[hot] = source[hot]
    return Image.fromarray((result * 255).round().astype(np.uint8), "RGB").convert("RGBA")


def preview(file):
    surfaces = {name: Image.open(art.path("surfaces", f"{name}.png")).convert("RGBA") for name in ("temperate", "boreal", "mountain")}
    surfaces["volcano"] = volcano_surface().convert("RGBA")
    surfaces["lshallow"] = lava_surface(False).convert("RGBA")
    surfaces["ldeep"] = lava_surface(True).convert("RGBA")
    faces = {name: Image.open(art.path("surfaces", f"{name}.png")).convert("RGBA") for name in ("cliff", "side")}
    faces["volcano_cliff"] = volcano_cliff().convert("RGBA")
    transitions = art.put_rows(Image.open(art.path("transitions", "transitions.png")).convert("RGBA"), transition_rows(), 174, VOLCANO_ROW)
    drips = art.put_rows(Image.open(art.path("transitions", "drips.png")).convert("RGBA"), drip_rows(), 32, DRIP_ROW)
    sheet = art.put_rows(Image.open(art.path("decorations", "decorations.png")).convert("RGBA"), decoration_rows(), 64, FIRST_ROW)
    rows_of = dict(DECORATION_ROWS)
    rows_of.update({slug: FIRST_ROW + k for k, (slug, _n, _f) in enumerate(KINDS)})
    day, glows = render(preview_map(), surfaces, faces, transitions, drips, sheet, rows_of)
    dark = night(day, glows)
    scale = 3
    font = glacier.label_font(26)
    title_h = 40
    pair = Image.new("RGBA", (day.width * scale, (day.height * scale + title_h) * 2), (24, 30, 40, 255))
    draw = ImageDraw.Draw(pair)
    for index, (image, title) in enumerate(((day, "De dia"), (dark, "À noite (meia-noite)"))):
        y0 = index * (day.height * scale + title_h)
        draw.text((8, y0 + 6), title, fill=(230, 236, 244), font=font)
        pair.paste(image.resize((image.width * scale, image.height * scale), Image.NEAREST), (0, y0 + title_h))

    rows = decoration_rows()
    zoom = 6
    crop_top = 14
    cell_h = 64 - crop_top
    strip_w = 48 * 4 * zoom
    label_h = 30
    small = glacier.label_font(20)
    lines = (len(KINDS) + 1) // 2
    strip = Image.new("RGBA", (strip_w * 2 + 40, (cell_h * zoom + label_h) * lines), (24, 30, 40, 255))
    draw = ImageDraw.Draw(strip)
    for index, (slug, name, _kind) in enumerate(KINDS):
        col, line = index % 2, index // 2
        x0 = col * (strip_w + 40)
        y0 = line * (cell_h * zoom + label_h)
        back = surfaces["lshallow" if slug == "lava_crust" else "volcano"]
        tile = back.crop((40, 40, 40 + 48 * 4, 40 + cell_h)).copy()
        tile.alpha_composite(rows.crop((0, index * 64 + crop_top, 48 * 4, index * 64 + 64)))
        strip.paste(tile.resize((strip_w, cell_h * zoom), Image.NEAREST), (x0, y0 + label_h))
        draw.text((x0 + 4, y0 + 4), name + (" (peça, com o bloqueio em azul)" if slug == "lava_crack" else ""), fill=(230, 236, 244), font=small)
        if slug == "lava_crack":
            for variant, points in enumerate(fissure_blocks()):
                pts = [(x0 + (variant * 48 + BX + points[k]) * zoom, y0 + label_h + (BY + points[k + 1] - crop_top) * zoom) for k in range(0, len(points), 2)]
                draw.line(pts + pts[:1], fill=(80, 220, 255), width=3)
    full = Image.new("RGBA", (max(pair.width, strip.width), pair.height + strip.height + 40), (24, 30, 40, 255))
    full.paste(pair, (0, 0))
    ImageDraw.Draw(full).text((8, pair.height + 6), "As decorações (4 variantes de cada, ampliadas 6 vezes)", fill=(230, 236, 244), font=font)
    full.paste(strip, (0, pair.height + 40))
    full.convert("RGB").save(file)


def main():
    volcano_surface().save(art.path("surfaces", "volcano.png"))
    volcano_cliff().save(art.path("surfaces", "volcano_cliff.png"))
    lava_surface(False).save(art.path("surfaces", "lshallow.png"))
    lava_surface(True).save(art.path("surfaces", "ldeep.png"))
    file = art.path("transitions", "transitions.png")
    sheet = Image.open(file).convert("RGBA")
    art.put_rows(sheet, transition_rows(), art.TRANSITION_CELL[1] * art.TRANSITION_VARIANTS, VOLCANO_ROW).save(file)
    file = art.path("transitions", "drips.png")
    art.put_rows(Image.open(file).convert("RGBA"), drip_rows(), art.DRIP_CELL_HEIGHT * 2, DRIP_ROW).save(file)
    file = art.path("decorations", "decorations.png")
    art.put_rows(Image.open(file).convert("RGBA"), decoration_rows(), nature.CELL[1], FIRST_ROW).save(file)


if __name__ == "__main__":
    if "--preview" in sys.argv:
        preview(sys.argv[sys.argv.index("--preview") + 1])
    else:
        main()
    print("ok")
