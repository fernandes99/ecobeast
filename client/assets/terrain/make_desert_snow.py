"""Gera a arte provisória do Deserto e da Neve (.specs/desert-snow/02-biome-art.md).

Uso: python -I make_desert_snow.py   (precisa do Pillow; roda de dentro de assets/terrain)

Recolore a arte de hoje pela luminância, sem imagem de terceiros:
- surfaces/desert.png e surfaces/snow.png, a partir de surfaces/hill.png;
- as linhas 6 e 7 de transitions/transitions.png, a partir das da Colina e da Planície;
- as linhas 3 e 4 de transitions/drips.png, a partir das da Colina;
- as linhas 17 a 22 de decorations/decorations.png: o cacto desenhado aqui, e o resto
  recolorido, com neve no alto das pedras, do pinheiro e do arbusto.
Rodar de novo regrava só essas linhas.
"""

import os
import random

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))

SAND = [(150, 106, 62), (190, 146, 90), (218, 180, 116), (233, 202, 140), (246, 226, 170)]
SNOW = [(132, 152, 186), (178, 198, 224), (212, 226, 242), (232, 240, 250), (250, 252, 255)]
SANDSTONE = [(92, 52, 34), (150, 88, 52), (196, 128, 76), (224, 168, 108), (242, 206, 150)]
FROST = [(70, 96, 104), (120, 150, 156), (168, 196, 198), (208, 228, 228), (240, 250, 250)]
SNOW_CAP = [(196, 212, 236), (236, 244, 252)]
SHADOW = (12, 26, 18, 72)

TRANSITION_CELL = (64, 58)
TRANSITION_VARIANTS = 3
DRIP_CELL_HEIGHT = 16
DECORATION_CELL = (48, 64)
DECORATION_BASE = (24, 60)


def path(*parts):
    return os.path.join(HERE, *parts)


def luminance(color):
    return 0.299 * color[0] + 0.587 * color[1] + 0.114 * color[2]


def ramp(colors, t):
    t = min(max(t, 0.0), 1.0) * (len(colors) - 1)
    index = min(int(t), len(colors) - 2)
    part = t - index
    a, b = colors[index], colors[index + 1]
    return tuple(round(a[k] + (b[k] - a[k]) * part) for k in range(3))


def recolor(image, colors, skip_shadow=True, steps=False):
    """Leva cada cor da imagem para a rampa pela posição da luminância entre a mais escura e a
    mais clara. Com `steps`, cada cor vai para a cor mais perto da rampa, sem misturar."""
    image = image.convert("RGBA")
    pixels = image.load()
    width, height = image.size
    lums = [
        luminance(pixels[x, y])
        for y in range(height)
        for x in range(width)
        if pixels[x, y][3] > 0 and not (skip_shadow and pixels[x, y] == SHADOW)
    ]
    if not lums:
        return image
    low, high = min(lums), max(lums)
    span = max(high - low, 1.0)
    for y in range(height):
        for x in range(width):
            pixel = pixels[x, y]
            if pixel[3] == 0 or (skip_shadow and pixel == SHADOW):
                continue
            t = (luminance(pixel) - low) / span
            color = colors[round(t * (len(colors) - 1))] if steps else ramp(colors, t)
            pixels[x, y] = color + (pixel[3],)
    return image


def snow_capped(image, depth):
    """Pinta de neve o alto de cada forma e de cada camada: os pixels com vazio ou com o
    contorno escuro até `depth` acima."""
    image = image.copy()
    source = image.load()
    width, height = image.size
    lums = [luminance(source[x, y]) for y in range(height) for x in range(width) if source[x, y][3] == 255]
    outline = min(lums) + (max(lums) - min(lums)) * 0.15 if lums else 0
    solid = lambda x, y: 0 <= y < height and source[x, y][3] == 255 and luminance(source[x, y]) > outline
    caps = []
    for y in range(height):
        for x in range(width):
            if not solid(x, y):
                continue
            for step in range(1, depth + 1):
                if not solid(x, y - step):
                    caps.append((x, y, step))
                    break
    for x, y, step in caps:
        source[x, y] = SNOW_CAP[1 if step == 1 else 0] + (255,)
    return image


def surface(name, colors):
    recolor(Image.open(path("surfaces", "hill.png")), colors).convert("RGB").save(path("surfaces", name))


def sheet_rows(image, row_height, first, count):
    return image.crop((0, first * row_height, image.width, (first + count) * row_height))


def put_rows(image, rows, row_height, first):
    needed = (first * row_height) + rows.height
    if image.height < needed:
        grown = Image.new("RGBA", (image.width, needed), (0, 0, 0, 0))
        grown.paste(image, (0, 0))
        image = grown
    image.paste(Image.new("RGBA", rows.size, (0, 0, 0, 0)), (0, first * row_height))
    image.paste(rows, (0, first * row_height))
    return image


def transitions():
    file = path("transitions", "transitions.png")
    sheet = Image.open(file).convert("RGBA")
    height = TRANSITION_CELL[1] * TRANSITION_VARIANTS
    hill = sheet_rows(sheet, height, 3, 1)
    grass = sheet_rows(sheet, height, 1, 1)
    sheet = put_rows(sheet, recolor(hill, SAND), height, 6)
    sheet = put_rows(sheet, recolor(grass, SNOW[1:]), height, 7)
    sheet.save(file)


def drips():
    file = path("transitions", "drips.png")
    sheet = Image.open(file).convert("RGBA")
    height = DRIP_CELL_HEIGHT * 2
    hill = sheet_rows(sheet, height, 2, 1)
    sheet = put_rows(sheet, recolor(hill, SAND, skip_shadow=False), height, 3)
    sheet = put_rows(sheet, recolor(hill, SNOW, skip_shadow=False), height, 4)
    sheet.save(file)


def shadow(cell, radius_x, radius_y):
    pixels = cell.load()
    cx, cy = DECORATION_BASE
    for y in range(cy - radius_y, cy + radius_y + 1):
        for x in range(cx - radius_x, cx + radius_x + 1):
            if ((x - cx) / (radius_x + 0.5)) ** 2 + ((y - cy) / (radius_y + 0.5)) ** 2 <= 1.0:
                pixels[x, y] = SHADOW


CACTUS = [(28, 64, 40), (48, 104, 58), (74, 146, 76), (116, 186, 98), (226, 224, 176)]


def cactus_column(points, left, top, bottom, width):
    """Uma coluna de cacto, com o alto arredondado, sombra à direita e luz à esquerda."""
    for y in range(top, bottom + 1):
        inset = 1 if y == top else 0
        for x in range(left + inset, left + width - inset):
            points[(x, y)] = 3 if x == left + inset else (1 if x == left + width - 1 - inset else 2)


def cactus(variant, rng):
    cell = Image.new("RGBA", DECORATION_CELL, (0, 0, 0, 0))
    shadow(cell, 6, 2)
    points = {}
    base = DECORATION_BASE[1]
    cx = DECORATION_BASE[0]
    if variant == 2:
        for y in range(base - 9, base + 1):
            half = round(5 * (1 - ((y - (base - 4.5)) / 5.5) ** 2) ** 0.5) if abs(y - (base - 4.5)) <= 5.5 else 0
            for x in range(cx - half, cx + half + 1):
                points[(x, y)] = 3 if x < cx - half + 2 else (1 if x > cx + half - 2 else 2)
    else:
        tall = [26, 22, 0, 18][variant]
        cactus_column(points, cx - 3, base - tall, base, 7)
        arms = {0: [(-1, 12, 8), (1, 9, 6)], 1: [(-1, 9, 7)], 3: [(1, 7, 6)]}[variant]
        for side, height, rise in arms:
            y = base - height
            outer = cx - 3 - 4 if side < 0 else cx + 4 + 1
            for x in range(min(outer, cx), max(outer + 4, cx)):
                for k in range(2):
                    if (x, y - k) not in points:
                        points[(x, y - k)] = 2 if k == 0 else 3
            cactus_column(points, outer, y - rise, y, 4)
    pixels = cell.load()
    for (x, y), shade in points.items():
        around = [(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
        edge = any(spot not in points for spot in around)
        pixels[x, y] = CACTUS[0 if edge else shade] + (255,)
    for _ in range(6):
        x, y = rng.choice(sorted(points))
        if pixels[x, y][:3] != CACTUS[0]:
            pixels[x, y] = CACTUS[4] + (255,)
    return cell


def decorations():
    file = path("decorations", "decorations.png")
    sheet = Image.open(file).convert("RGBA")
    height = DECORATION_CELL[1]
    rng = random.Random(17)
    row = lambda index: sheet_rows(sheet, height, index, 1)
    cacti = Image.new("RGBA", (sheet.width, height), (0, 0, 0, 0))
    for variant in range(4):
        cacti.paste(cactus(variant, rng), (variant * DECORATION_CELL[0], 0))
    made = [
        cacti,
        recolor(row(13), SANDSTONE),
        snow_capped(recolor(row(1), [(10, 34, 36), (20, 58, 54), (34, 86, 74), (52, 112, 92), (178, 198, 226), (236, 244, 252)], steps=True), 1),
        snow_capped(recolor(row(11), [(60, 66, 80), (100, 108, 124), (140, 148, 164), (190, 198, 212)]), 3),
        snow_capped(recolor(row(3), [(14, 40, 40), (34, 82, 74), (60, 118, 100), (178, 198, 226), (236, 244, 252)], steps=True), 1),
        recolor(row(8), FROST),
    ]
    for offset, rows in enumerate(made):
        sheet = put_rows(sheet, rows, height, 17 + offset)
    sheet.save(file)


if __name__ == "__main__":
    surface("desert.png", SAND)
    surface("snow.png", SNOW)
    transitions()
    drips()
    decorations()
    print("ok")
