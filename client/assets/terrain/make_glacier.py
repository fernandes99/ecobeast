"""Desenha a arte da Geleira (.specs/glacier/01-glacier-art.md).

Uso: python -I make_glacier.py [--preview saida.png]   (precisa do Pillow e do numpy)

Grava, só por código:
- surfaces/glacier.png, o chão de gelo, que se repete sem emenda;
- a linha 9 de transitions/transitions.png (a borda do gelo, da linha da Pedra recolorida);
- a linha 6 de transitions/drips.png (os sincelos no alto do paredão);
- as linhas 66 a 71 de decorations/decorations.png, no traço do make_nature.py.
Rodar de novo regrava só essas linhas. Com --preview, grava só a prévia ampliada.
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
import make_nature as nature  # noqa: E402

TRANSITION_ROW = 9
DRIP_ROW = 6
FIRST_ROW = 66
SURFACE_SIZE = 512
BX, BY = nature.BASE

FLOOR = [(88, 156, 204), (116, 182, 224), (146, 204, 238), (178, 224, 248), (210, 240, 252)]
VEIN_LIGHT = (236, 250, 255)
VEIN_DARK = (74, 136, 186)
GLINT = (252, 255, 255)
EDGE = [(70, 120, 160), (120, 176, 210), (170, 214, 236), (214, 240, 250), (244, 252, 255)]
ICE = nature.ICE
DRIFT = [(118, 140, 180), (168, 190, 222), (204, 220, 240), (232, 242, 252), (250, 253, 255)]
FROST = (176, 222, 242)
FOAM = (230, 246, 252)


class FreeCell(nature.Cell):
    """Uma célula que aceita cor com alfa e só tem a sombra no pé quando pedida."""

    def image(self, shadow=None):
        cell = nature.Cell.image(self, shadow) if shadow else Image.new("RGBA", nature.CELL, (0, 0, 0, 0))
        data = cell.load()
        for (x, y), color in self.pixels.items():
            data[x, y] = tuple(color) if len(color) == 4 else tuple(color) + (255,)
        return cell


def frost(color, alpha, mix=0.3):
    """A cor vista por baixo do gelo: puxada para o azul do gelo e meio transparente."""
    return tuple(round(c * (1 - mix) + f * mix) for c, f in zip(color[:3], FROST)) + (alpha,)


# O chão ------------------------------------------------------------------------------------


def periodic_noise(rng, cells_x, cells_y, size=SURFACE_SIZE):
    grid = rng.random((cells_y, cells_x))
    u = np.arange(size) * cells_x / size
    v = np.arange(size) * cells_y / size
    x0 = np.floor(u).astype(int)
    y0 = np.floor(v).astype(int)
    fx = u - x0
    fy = v - y0
    fx = fx * fx * (3 - 2 * fx)
    fy = fy * fy * (3 - 2 * fy)
    x1 = (x0 + 1) % cells_x
    y1 = (y0 + 1) % cells_y
    x0 %= cells_x
    y0 %= cells_y
    top = grid[y0][:, x0] * (1 - fx) + grid[y0][:, x1] * fx
    bottom = grid[y1][:, x0] * (1 - fx) + grid[y1][:, x1] * fx
    return top * (1 - fy)[:, None] + bottom * fy[:, None]


def surface():
    rng = np.random.default_rng(1212)
    fbm = (
        0.5 * periodic_noise(rng, 4, 4)
        + 0.25 * periodic_noise(rng, 8, 8)
        + 0.15 * periodic_noise(rng, 16, 16)
        + 0.1 * periodic_noise(rng, 32, 32)
    )
    bands = periodic_noise(rng, 2, 20)
    value = 0.65 * fbm + 0.35 * bands
    low, high = np.percentile(value, 2), np.percentile(value, 98)
    value = np.clip((value - low) / (high - low), 0.0, 0.999)
    levels = len(FLOOR)
    scaled = value * levels
    index = scaled.astype(int)
    bayer = np.tile(np.array(nature.BAYER), (SURFACE_SIZE // 2, SURFACE_SIZE // 2))
    index = np.minimum(index + (scaled - index > bayer), levels - 1)
    palette = np.array(FLOOR, dtype=np.uint8)
    image = Image.fromarray(palette[index], "RGB")
    pixels = image.load()
    pick = random.Random("glacier-surface")

    def put(x, y, color):
        pixels[x % SURFACE_SIZE, y % SURFACE_SIZE] = color

    def vein(x, y, angle, length, dark_only):
        for _ in range(length):
            px, py = round(x), round(y)
            if dark_only:
                put(px, py, VEIN_DARK)
                put(px, py - 1, VEIN_LIGHT)
            else:
                put(px, py, VEIN_LIGHT)
                put(px, py + 1, VEIN_DARK)
            x += math.cos(angle)
            y += math.sin(angle) * 0.6
            angle += pick.uniform(-0.18, 0.18)
            if pick.random() < 0.025:
                vein(x, y, angle + pick.choice([-1, 1]) * pick.uniform(0.6, 1.1), pick.randint(5, 14), dark_only)

    for _ in range(34):
        angle = pick.uniform(-0.5, 0.5) + (math.pi if pick.random() < 0.5 else 0.0)
        vein(pick.uniform(0, SURFACE_SIZE), pick.uniform(0, SURFACE_SIZE), angle, pick.randint(24, 80), pick.random() < 0.35)
    for _ in range(70):
        x, y = pick.randrange(SURFACE_SIZE), pick.randrange(SURFACE_SIZE)
        put(x, y, FLOOR[4])
        put(x + 1, y, FLOOR[4])
    for _ in range(170):
        put(pick.randrange(SURFACE_SIZE), pick.randrange(SURFACE_SIZE), GLINT)
    for _ in range(22):
        x, y = pick.randrange(SURFACE_SIZE), pick.randrange(SURFACE_SIZE)
        put(x, y, GLINT)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            put(x + dx, y + dy, VEIN_LIGHT)
    return image


# Os arremates e o escorrido ---------------------------------------------------------------------


def transition_row():
    sheet = Image.open(art.path("transitions", "transitions.png")).convert("RGBA")
    height = art.TRANSITION_CELL[1] * art.TRANSITION_VARIANTS
    stone = art.sheet_rows(sheet, height, 4, 1)
    return art.recolor(stone, EDGE)


def drip_rows():
    width = 32
    rows = Image.new("RGBA", (width * 4, art.DRIP_CELL_HEIGHT * 2), (0, 0, 0, 0))
    pixels = rows.load()
    for long in (0, 1):
        top = long * art.DRIP_CELL_HEIGHT
        for variant in range(4):
            rng = random.Random(f"icicles:{long}:{variant}")
            left = variant * width
            for x in range(width):
                pixels[left + x, top] = EDGE[3] + (255,)
                pixels[left + x, top + 1] = EDGE[2] + (255,)
                if rng.random() < 0.5:
                    pixels[left + x, top + 2] = EDGE[1] + (255,)
            x = rng.randint(0, 3)
            while x < width:
                size = rng.choice([1, 2, 2, 3])
                length = rng.randint(2, 6) if not long else rng.randint(4, 14)
                for k in range(length):
                    w = max(1, round(size * (1 - k / length)))
                    for dx in range(w):
                        if x + dx >= width:
                            continue
                        color = EDGE[4] if dx == 0 else (EDGE[1] if dx == w - 1 and w > 1 else EDGE[2])
                        pixels[left + x + dx, top + 2 + k] = color + (255,)
                x += size + rng.randint(1, 5)
    return rows


# As decorações ----------------------------------------------------------------------------------


def ice_crack(cell, variant):
    rng = cell.rng
    dark = (80, 136, 180, 220)
    light = (240, 252, 255, 200)

    def mark(x, y):
        cell.put(x, y, dark)
        if (x, y - 1) not in cell.pixels:
            cell.put(x, y - 1, light)

    if variant == 2:
        cx, cy = BX, BY - 5
        for ray in range(rng.randint(5, 6)):
            angle = ray / 5.5 * math.tau + rng.uniform(-0.3, 0.3)
            for step in range(1, rng.randint(4, 8)):
                mark(round(cx + math.cos(angle) * step), round(cy + math.sin(angle) * step * 0.6))
        return None
    length = rng.randint(14, 22)
    y = BY - 4 + rng.randint(-2, 2)
    main = []
    for x in range(BX - length // 2, BX + length // 2):
        y = min(max(y + rng.choice([-1, 0, 0, 1]), BY - 9), BY - 1)
        mark(x, y)
        main.append((x, y))
    for _ in range(rng.randint(1, 3)):
        x, y = rng.choice(main[2:-2])
        dx, dy = rng.choice([-1, 1]), rng.choice([-1, 1])
        for _ in range(rng.randint(3, 6)):
            x += dx if rng.random() < 0.7 else 0
            y += dy if rng.random() < 0.5 else 0
            mark(x, y)
    return None


def ice_bubbles(cell, variant):
    rng = cell.rng
    for _ in range(rng.randint(5, 9)):
        a = rng.uniform(0, math.tau)
        d = math.sqrt(rng.random())
        x, y = round(BX + math.cos(a) * d * 9), round(BY - 4 + math.sin(a) * d * 4)
        size = rng.choice([0, 0, 1, 1, 2])
        if size == 0:
            cell.put(x, y, (236, 250, 255, 150))
        elif size == 1:
            cell.put(x, y, (190, 230, 246, 115))
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                cell.put(x + dx, y + dy, (236, 250, 255, 160))
            cell.put(x - 1, y - 1, (255, 255, 255, 178))
        else:
            for dy in range(-2, 2):
                for dx in range(-2, 3):
                    inside = (dx / 2.5) ** 2 + ((dy + 0.5) / 2.0) ** 2
                    if inside <= 1.0:
                        ring = inside > 0.45
                        cell.put(x + dx, y + dy, (236, 250, 255, 165) if ring else (190, 230, 246, 115))
            cell.put(x - 1, y - 1, (255, 255, 255, 178))
    return None


def shard(cell, cx, cy, radius, angle):
    corners = []
    for k in range(3):
        a = angle + k * math.tau / 3 + cell.rng.uniform(-0.4, 0.4)
        r = radius * (1.0 if k == 0 else cell.rng.uniform(0.45, 0.7))
        corners.append((cx + math.cos(a) * r, cy + math.sin(a) * r * 0.6))
    mask = Image.new("1", nature.CELL, 0)
    ImageDraw.Draw(mask).polygon(corners, fill=1)
    inside = {(x, y) for y in range(nature.CELL[1]) for x in range(nature.CELL[0]) if mask.getpixel((x, y))}
    for x, y in inside:
        if (x, y + 1) not in inside:
            cell.put(x, y + 1, ICE[1])
    for x, y in inside:
        lit = (x - 1, y) not in inside or (x, y - 1) not in inside
        dark = (x + 1, y) not in inside
        cell.put(x, y, ICE[4] if lit else (ICE[2] if dark else ICE[3]))


def ice_chips(cell, variant):
    rng = cell.rng
    for _ in range(rng.randint(3, 4)):
        shard(cell, BX + rng.uniform(-8, 8), BY - 3 + rng.uniform(-3, 2), rng.uniform(2.5, 4.5), rng.uniform(0, math.tau))
    if variant == 3:
        x = BX + rng.randint(-3, 3)
        for step in range(5):
            cell.put(x, BY - 2 - step, ICE[4] if step % 2 else ICE[3])
            cell.put(x + 1, BY - 2 - step, ICE[1] if step < 4 else ICE[2])
    return (6, 1)


def snow_drift(cell, variant):
    rng = cell.rng
    mounds = [(BX + rng.uniform(-6, 6), rng.uniform(4.5, 9.0), rng.uniform(3.0, 5.5)) for _ in range(rng.randint(1, 3))]

    def height(x):
        best = 0.0
        for cx, w, h in mounds:
            d = (x + 0.5 - cx) / w
            if abs(d) < 1.0:
                best = max(best, h * math.sqrt(1 - d * d))
        return best

    shape = {}
    for x in range(nature.CELL[0]):
        top = height(x)
        if top < 0.6:
            continue
        for y in range(round(BY - top), BY + 1):
            shape[(x, y)] = (top, (BY - y) / max(top, 1.0))
    tones = DRIFT[1:]
    for (x, y), (top, t) in shape.items():
        if any((x + dx, y + dy) not in shape for dx, dy in ((1, 0), (-1, 0), (0, -1))):
            cell.put(x, y, DRIFT[0])
            continue
        slope = (height(x + 1) - height(x - 1)) / 2.0
        ny = -0.9 if t > 0.6 else (0.5 if t < 0.25 else -0.2)
        cell.put(x, y, tones[nature.shade_index(max(-0.9, min(0.9, -slope * 0.6)), ny, len(tones), x, y)])
    for x, y in list(shape):
        if (x, y + 1) not in shape and cell.pixels.get((x, y)) != DRIFT[0] and rng.random() < 0.5:
            cell.put(x, y, DRIFT[1])
    width = max(round(abs(cx - BX) + w) for cx, w, _ in mounds)
    return (min(width, 12), 1)


FISH = [
    [(56, 72, 92), (110, 132, 150), (176, 194, 204), (220, 230, 236)],
    [(120, 52, 30), (204, 100, 50), (240, 152, 80), (252, 210, 150)],
    [(44, 64, 48), (88, 112, 74), (140, 156, 104), (196, 204, 160)],
]


def fish(cell, cx, cy, length, angle, colors, alpha):
    body = length * 0.7
    tail = length - body
    width = length * 0.2
    ca, sa = math.cos(angle), math.sin(angle)
    shape = {}
    for y in range(int(cy - length), int(cy + length) + 1):
        for x in range(int(cx - length), int(cx + length) + 1):
            dx, dy = x + 0.5 - cx, (y + 0.5 - cy) / 0.7
            u = dx * ca + dy * sa + tail
            v = -dx * sa + dy * ca
            if 0 <= u <= tail + body:
                if u >= tail:
                    k = (u - tail) / body
                    half = width * math.sin(math.pi * min(1.0, k * 1.15)) ** 0.6 if k < 0.87 else width * (1 - k) * 4
                    if abs(v) <= half:
                        shape[(x, y)] = ("body", u, v, half)
                else:
                    k = 1 - u / tail
                    half = width * 1.2 * k
                    if abs(v) <= half and not (k > 0.55 and abs(v) < half * 0.35):
                        shape[(x, y)] = ("tail", u, v, half)
    for (x, y), (part, u, v, half) in shape.items():
        edge = any((x + dx, y + dy) not in shape for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if edge:
            color = colors[0]
        elif part == "tail":
            color = colors[1]
        else:
            color = colors[1] if abs(v) < half * 0.3 else (colors[3] if v < 0 else colors[2])
        cell.put(x, y, frost(color, alpha if not edge else alpha + 20))
    eye_u = tail + body * 0.82
    ex = cx + (eye_u - tail) * ca - (-width * 0.35) * sa
    ey = cy + ((eye_u - tail) * sa + (-width * 0.35) * ca) * 0.7
    cell.put(round(ex - 0.5), round(ey - 0.5), frost((20, 24, 30), alpha + 20, 0.2))


def frozen_fish(cell, variant):
    rng = cell.rng
    alpha = 165
    if variant == 3:
        for k in range(2):
            fish(cell, BX - 5 + k * 9, BY - 6 + k * 3, rng.uniform(10, 12), rng.uniform(-0.5, 0.5) + (math.pi if k else 0), FISH[0], alpha)
    else:
        fish(cell, BX, BY - 6, rng.uniform(16, 19), rng.uniform(-0.6, 0.6) + rng.choice([0, math.pi]), FISH[variant], alpha)
    for _ in range(rng.randint(2, 4)):
        cell.put(BX + rng.randint(-9, 9), BY - 5 + rng.randint(-4, 3), (236, 250, 255, 140))
    return None


def floe(cell, cx, cy, rx, ry, snow):
    rng = cell.rng
    count = rng.randint(6, 7)
    corners = []
    for k in range(count):
        a = (k + rng.uniform(-0.3, 0.3)) / count * math.tau
        r = rng.uniform(0.75, 1.05)
        corners.append((cx + math.cos(a) * rx * r, cy + math.sin(a) * ry * r))
    mask = Image.new("1", nature.CELL, 0)
    ImageDraw.Draw(mask).polygon(corners, fill=1)
    top = {(x, y) for y in range(nature.CELL[1]) for x in range(nature.CELL[0]) if mask.getpixel((x, y))}
    side = {(x, y + k) for x, y in top for k in (1, 2) if (x, y + k) not in top}
    under = {(x, y + k) for x, y in top | side for k in (1, 2) if (x, y + k) not in top and (x, y + k) not in side}
    solid = top | side
    for x, y in sorted(solid):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (2, 0), (-2, 0)):
            spot = (x + dx, y + dy)
            if spot not in solid and spot not in cell.pixels and rng.random() < 0.6:
                cell.put(*spot, FOAM + (130,))
    for x, y in sorted(under):
        if (x, y) not in solid:
            cell.put(x, y, (150, 204, 232, 110))
    for x, y in sorted(side):
        bottom = (x, y + 1) not in side
        cell.put(x, y, (78, 136, 184) if bottom else (120, 176, 212))
    for x, y in sorted(top):
        rim = (x, y - 1) not in top or (x - 1, y) not in top
        front = (x, y + 1) not in top or (x + 1, y) not in top
        cell.put(x, y, (250, 254, 255) if rim else ((176, 214, 236) if front else (224, 240, 249)))
    inside = [spot for spot in sorted(top) if cell.pixels[spot] == (224, 240, 249)]
    if len(inside) > 12:
        x, y = rng.choice(inside[: len(inside) // 2])
        for _ in range(rng.randint(3, round(rx))):
            if (x, y) in top and (x, y + 1) in top:
                cell.put(x, y, (150, 196, 226))
                cell.put(x, y + 1, (250, 254, 255))
            x += 1
            y += rng.choice([-1, 0, 0, 1])
    if snow:
        for x, y in sorted(top):
            if abs(x + 0.5 - cx) < rx * 0.5 and abs(y + 0.5 - cy) < ry * 0.45 and rng.random() < 0.7:
                cell.put(x, y, (255, 255, 255))
                if rng.random() < 0.3:
                    cell.put(x, y - 1, (255, 255, 255))


def ice_floe(cell, variant):
    rng = cell.rng
    if variant == 2:
        for k, (dx, dy) in enumerate(((-7, -1), (5, -3), (2, 3))):
            floe(cell, BX + dx, BY - 6 + dy, rng.uniform(3.5, 5.0), rng.uniform(1.4, 2.0), False)
        return None
    rx = [11.0, 8.0, 0, 9.5][variant]
    ry = rx * rng.uniform(0.34, 0.42)
    floe(cell, BX, BY - ry - 3, rx, ry, variant == 3)
    return None


KINDS = [
    ("ice_crack", "Rachadura no gelo", ice_crack),
    ("ice_bubbles", "Bolhas no gelo", ice_bubbles),
    ("ice_chips", "Lascas de gelo", ice_chips),
    ("snow_drift", "Neve soprada", snow_drift),
    ("frozen_fish", "Peixe no gelo", frozen_fish),
    ("ice_floe", "Placa de gelo", ice_floe),
]


def decoration_rows():
    rows = Image.new("RGBA", (nature.CELL[0] * 4, nature.CELL[1] * len(KINDS)), (0, 0, 0, 0))
    for row, (slug, _name, kind) in enumerate(KINDS):
        for variant in range(4):
            cell = FreeCell(random.Random(f"{slug}:{variant}"))
            shadow = kind(cell, variant)
            rows.paste(cell.image(shadow), (variant * nature.CELL[0], row * nature.CELL[1]))
    return rows


# A prévia ---------------------------------------------------------------------------------------

STEP_X, STEP_Y, ROW_SHIFT = 64, 42, 32
HEX = [(32, 0), (64, 16), (64, 42), (32, 58), (0, 42), (0, 16)]
NEIGHBORS = [(1, -1), (1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1)]
LOWER = [((-1, 1), (4, 3), 1.0), ((0, 1), (3, 2), 0.76)]
SURFACE_ORDER = ["beach", "desert", "temperate", "boreal", "hill", "glacier", "snow", "stone", "mountain"]
MATERIAL_ROWS = {"foam": 0, "stone": 4, "snow": 7, "glacier": TRANSITION_ROW}
DRIP_ROWS = {"snow": 4, "glacier": DRIP_ROW}
CLIFF = ["stone", "mountain", "glacier"]
DECORATION_ROWS = {
    "snow_pine": 19, "snow_rock": 20, "snow_bush": 21, "snow_tuft": 22, "frozen_branch": 43, "ice_shards": 44,
    "winter_berry": 45, "snow_log": 46, "spire": 16, "boulder": 14, "rock_pile": 15, "moss": 9, "slab": 37,
    "lichen_rock": 38,
}
RADIUS = {
    "snow_pine": 12, "snow_rock": 9, "snow_bush": 10, "snow_tuft": 4, "frozen_branch": 7, "ice_shards": 7,
    "winter_berry": 10, "snow_log": 11, "spire": 13, "boulder": 14, "rock_pile": 12, "moss": 4, "slab": 11,
    "lichen_rock": 9, "ice_crack": 9, "ice_bubbles": 6, "ice_chips": 6, "snow_drift": 8, "frozen_fish": 7,
    "ice_floe": 9,
}
RECIPES = {
    "snow": [["snow_pine", 0.4, 1, 3], ["snow_rock", 0.14, 1, 1], ["snow_bush", 0.24, 1, 2], ["snow_tuft", 0.4, 1, 3], ["snow_log", 0.08, 1, 1], ["winter_berry", 0.14, 1, 1], ["frozen_branch", 0.12, 1, 1], ["ice_shards", 0.1, 1, 1]],
    "stone": [["spire", 0.2, 1, 1], ["boulder", 0.34, 1, 2], ["rock_pile", 0.3, 1, 2], ["moss", 0.2, 1, 2], ["slab", 0.14, 1, 1], ["lichen_rock", 0.16, 1, 1]],
    "glacier": [["ice_crack", 0.45, 1, 2], ["ice_bubbles", 0.3, 1, 1], ["ice_chips", 0.28, 1, 2], ["snow_drift", 0.3, 1, 1], ["ice_shards", 0.12, 1, 1], ["frozen_fish", 0.03, 1, 1]],
    "wshallow_ice_lake": [["ice_floe", 0.35, 1, 2]],
    "wdeep_ice_lake": [["ice_floe", 0.15, 1, 1]],
}


def preview_map():
    """Um mapa de 12 por 9: Pedra à esquerda, Neve em volta, a Geleira no meio com um lago, e as
    3 linhas de cima no nível 3, para o paredão aparecer."""
    tiles = {}
    center = (5, 5)
    for r in range(9):
        for c in range(12):
            q = c - r // 2
            cq = center[0] - center[1] // 2
            d = (abs(q - cq) + abs(r - center[1]) + abs(q - cq + r - center[1])) // 2
            biome = "stone" if c <= 1 else "snow"
            if d <= 3 and c >= 2:
                biome = "glacier"
            zone = ""
            if (q, r) in ((cq, center[1]),) or (d <= 1 and r >= 4):
                biome, zone = "wshallow", "wshallow_ice_lake"
            if (q, r) == (cq + 1, center[1]):
                biome, zone = "wdeep", "wdeep_ice_lake"
            height = 3 if r <= 2 else 0
            if biome.startswith("w"):
                height = 0
            tiles[(q, r)] = (biome, height, zone)
    return tiles


def label_font(size):
    from PIL import ImageFont

    try:
        return ImageFont.truetype("segoeui.ttf", size)
    except OSError:
        return ImageFont.load_default()


def preview(file):
    surfaces = {name: Image.open(art.path("surfaces", f"{name}.png")).convert("RGBA") for name in ("snow", "stone", "wshallow", "wdeep")}
    surfaces["glacier"] = surface().convert("RGBA")
    faces = {name: Image.open(art.path("surfaces", f"{name}.png")).convert("RGBA") for name in ("cliff", "side")}
    transitions = Image.open(art.path("transitions", "transitions.png")).convert("RGBA")
    transitions = art.put_rows(transitions, transition_row(), 174, TRANSITION_ROW)
    drips = art.put_rows(Image.open(art.path("transitions", "drips.png")).convert("RGBA"), drip_rows(), 32, DRIP_ROW)
    sheet = art.put_rows(Image.open(art.path("decorations", "decorations.png")).convert("RGBA"), decoration_rows(), 64, FIRST_ROW)
    rows_of = dict(DECORATION_ROWS)
    rows_of.update({slug: FIRST_ROW + k for k, (slug, _n, _f) in enumerate(KINDS)})
    tiles = preview_map()
    width, height = 12 * 64 + 32, 8 * 42 + 58 + 40
    lift = 30
    canvas = Image.new("RGBA", (width, height + lift), (24, 30, 40, 255))
    hex_mask = Image.new("L", (65, 59), 0)
    ImageDraw.Draw(hex_mask).polygon(HEX, fill=255)
    rise = lambda level: level * 8

    def origin(q, r):
        return 64 * q + 32 * r, 42 * r + lift

    def tint(biome, level):
        return 1.0 if biome.startswith("w") else 1.0 - 0.03 * max(5 - level, 0)

    def shaded(image, factor):
        if factor >= 0.999:
            return image
        r, g, b, a = image.split()
        r, g, b = (channel.point(lambda v: round(v * factor)) for channel in (r, g, b))
        return Image.merge("RGBA", (r, g, b, a))

    picked = random.Random("preview")
    fish_shown = False
    for r in range(9):
        row_tiles = sorted((q, rr) for q, rr in tiles if rr == r)
        decorations = []
        for q, _ in row_tiles:
            biome, level, zone = tiles[(q, r)]
            ox, oy = origin(q, r)
            oy -= rise(level)
            for (dq, dr), (a, b), face_shade in LOWER:
                neighbor = tiles.get((q + dq, r + dr))
                face = rise(level) - (rise(neighbor[1]) if neighbor else -26)
                if face <= 0 or biome.startswith("w"):
                    continue
                texture = faces["cliff" if biome in CLIFF else "side"]
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
                        canvas.putpixel((ox + x, round(oy + top + k)), tuple(round(c * f) for c in color[:3]) + (255,))
                    if drip is not None:
                        row = drip * 2 + (1 if face >= 16 else 0)
                        for k in range(min(face, 16)):
                            color = drips.getpixel((variant * 32 + (x - left), row * 16 + k))
                            if color[3]:
                                f = face_shade * tint(biome, level)
                                canvas.putpixel((ox + x, round(oy + top + k)), tuple(round(c * f) for c in color[:3]) + (255,))
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
                if neighbor_rank <= rank:
                    continue
                if (dq, dr) in ((-1, 1), (0, 1)) and neighbor[1] > level:
                    continue
                material = "foam" if biome.startswith("w") else neighbor[0]
                if material not in MATERIAL_ROWS:
                    continue
                row = MATERIAL_ROWS[material] * 3 + picked.randrange(3)
                cell = transitions.crop((edge * 64, row * 58, edge * 64 + 64, row * 58 + 58))
                canvas.alpha_composite(shaded(cell, tint(biome, level)), (ox, oy))
            recipe = RECIPES.get(zone or biome, [])
            placed = []
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
            if biome == "glacier" and not fish_shown and level == 0 and len(placed) < 3:
                placed.append(("frozen_fish", (-12, 8)))
                fish_shown = True
            for kind, spot in placed:
                decorations.append((oy + 29 + spot[1], ox + 32 + spot[0], kind, picked.randrange(4), picked.random() < 0.5))
        for base_y, base_x, kind, variant, flipped in sorted(decorations):
            row = rows_of[kind]
            cell = sheet.crop((variant * 48, row * 64, variant * 48 + 48, row * 64 + 64))
            if flipped:
                cell = cell.transpose(Image.FLIP_LEFT_RIGHT)
            canvas.alpha_composite(cell, (base_x - 24, base_y - 60))
    scale = 3
    big = canvas.resize((canvas.width * scale, canvas.height * scale), Image.NEAREST)

    rows = decoration_rows()
    zoom = 6
    crop_top = 30
    cell_h = 64 - crop_top
    strip_w = 48 * 4 * zoom
    label_h = 30
    font = label_font(20)
    strip = Image.new("RGBA", (strip_w * 2 + 40, (cell_h * zoom + label_h) * 3), (24, 30, 40, 255))
    draw = ImageDraw.Draw(strip)
    ice_back = shaded(surface().convert("RGBA"), 0.85)
    water_back = surfaces["wshallow"]
    for index, (slug, name, _kind) in enumerate(KINDS):
        col, line = index % 2, index // 2
        x0 = col * (strip_w + 40)
        y0 = line * (cell_h * zoom + label_h)
        tile = (water_back if slug == "ice_floe" else ice_back).crop((40, 40, 40 + 48 * 4, 40 + cell_h))
        tile.alpha_composite(rows.crop((0, index * 64 + crop_top, 48 * 4, index * 64 + 64)))
        strip.paste(tile.resize((strip_w, cell_h * zoom), Image.NEAREST), (x0, y0 + label_h))
        draw.text((x0 + 4, y0 + 4), name, fill=(230, 236, 244), font=font)
    full = Image.new("RGBA", (max(big.width, strip.width), big.height + strip.height + 30), (24, 30, 40, 255))
    full.paste(big, (0, 0))
    ImageDraw.Draw(full).text((8, big.height + 4), "As decorações (4 variantes de cada, ampliadas 6 vezes)", fill=(230, 236, 244), font=label_font(22))
    full.paste(strip, (0, big.height + 30))
    full.convert("RGB").save(file)


def main():
    surface().save(art.path("surfaces", "glacier.png"))
    file = art.path("transitions", "transitions.png")
    sheet = Image.open(file).convert("RGBA")
    art.put_rows(sheet, transition_row(), art.TRANSITION_CELL[1] * art.TRANSITION_VARIANTS, TRANSITION_ROW).save(file)
    file = art.path("transitions", "drips.png")
    art.put_rows(Image.open(file).convert("RGBA"), drip_rows(), art.DRIP_CELL_HEIGHT * 2, DRIP_ROW).save(file)
    file = art.path("decorations", "decorations.png")
    sheet = Image.open(file).convert("RGBA")
    art.put_rows(sheet, decoration_rows(), nature.CELL[1], FIRST_ROW).save(file)


if __name__ == "__main__":
    if "--preview" in sys.argv:
        preview(sys.argv[sys.argv.index("--preview") + 1])
    else:
        main()
    print("ok")
