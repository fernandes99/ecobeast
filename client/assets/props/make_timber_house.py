"""Monta a casa enxaimel do pacote Glassblower's Workshop (timber-house/01).

Uso: python -I make_timber_house.py <pasta Tiled_files do pacote>   (precisa do Pillow; roda de dentro de assets/props)

O pacote não tem a casa pronta: ela é desenhada por tiles de 16x16 no Exterior.tmx. O script
cola as camadas da casa (sem o chão, a tenda, a placa, o barril e a carroça), com o primeiro
quadro dos tiles animados (a porta fechada), recorta e grava timber_house/1.png a 8.png, as 8
cores, que mudam só o telhado, a madeira, a pedra e o reboco, pelo matiz, mantendo a luz e a
sombra de cada pixel. A fumaça é a da casa grande (big_house/smoke.png), copiada.
"""

import colorsys
import os
import shutil
import sys
import xml.etree.ElementTree as ET

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
TILE = 16
HOUSE_LAYERS = ("Walls", "Windows_top", "Roof", "stovepipe", "Roof_detail")
ROOF_HUE = 345
# Por variante: `hue` põe o grupo num matiz (o do telhado original vira ele); `turn` gira o
# matiz; `sat` e `val` multiplicam.
COLORS = [
    {},
    {"roof": {"hue": 215, "sat": 0.85}},
    {"roof": {"hue": 105, "sat": 0.7, "val": 0.95}, "stone": {"turn": 20, "sat": 1.4, "val": 1.12}},
    {"roof": {"hue": 28, "sat": 0.55, "val": 0.82}, "wood": {"val": 0.85}, "cream": {"sat": 0.3, "val": 1.08}},
    {"roof": {"hue": 225, "sat": 0.28, "val": 0.95}, "wood": {"sat": 0.55, "val": 0.8}, "stone": {"val": 0.8}},
    {"roof": {"hue": 285, "sat": 0.6}},
    {"roof": {"hue": 178, "sat": 0.65, "val": 0.95}, "wood": {"sat": 0.75, "val": 1.12}},
    {"roof": {"hue": 22, "sat": 1.0, "val": 1.15}, "stone": {"turn": 15, "sat": 1.5}},
]


def group(color):
    if color[3] < 255:
        return None
    h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in color[:3]))
    h *= 360
    if s >= 0.5 and h >= 320:
        return "roof"
    if s >= 0.42 and h < 45:
        return "wood"
    if s < 0.32 and (h < 40 or h > 340):
        return "stone" if v < 0.7 else "cream"
    return None


def house_of(folder):
    root = ET.parse(os.path.join(folder, "Exterior.tmx")).getroot()
    sheets = []
    for tileset in root.findall("tileset"):
        image = Image.open(os.path.join(folder, tileset.find("image").get("source"))).convert("RGBA")
        sheets.append((int(tileset.get("firstgid")), int(tileset.get("columns")), image))
    sheets.sort(key=lambda sheet: sheet[0])
    tiles = {}
    for layer in root.findall("layer"):
        if layer.get("name") not in HOUSE_LAYERS:
            continue
        for chunk in layer.find("data").findall("chunk"):
            x0, y0, width = int(chunk.get("x")), int(chunk.get("y")), int(chunk.get("width"))
            values = [int(v) for v in chunk.text.replace("\n", "").split(",") if v.strip()]
            for index, gid in enumerate(values):
                if gid:
                    tiles.setdefault(layer.get("name"), []).append((x0 + index % width, y0 + index // width, gid))
    cells = [(x, y) for layer in tiles.values() for x, y, _ in layer]
    left, top = min(x for x, _ in cells), min(y for _, y in cells)
    canvas = Image.new("RGBA", ((max(x for x, _ in cells) - left + 1) * TILE, (max(y for _, y in cells) - top + 1) * TILE))
    for name in HOUSE_LAYERS:
        for x, y, gid in tiles.get(name, []):
            if gid & 0xE0000000:
                sys.exit("tile espelhado no Exterior.tmx: o script não trata")
            first, columns, image = next(sheet for sheet in reversed(sheets) if gid >= sheet[0])
            index = gid - first
            tile = image.crop(((index % columns) * TILE, (index // columns) * TILE, (index % columns + 1) * TILE, (index // columns + 1) * TILE))
            canvas.alpha_composite(tile, ((x - left) * TILE, (y - top) * TILE))
    return canvas.crop(canvas.getbbox())


def shift(color, hue=None, turn=0.0, sat=1.0, val=1.0):
    r, g, b, a = color
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    if hue is not None:
        h = ((hue + (((h * 360 + 180 - ROOF_HUE) % 360) - 180) * 0.5) % 360) / 360
    h = (h + turn / 360) % 1.0
    r, g, b = colorsys.hsv_to_rgb(h, min(1.0, s * sat), min(1.0, v * val))
    return (round(r * 255), round(g * 255), round(b * 255), a)


def recolor(image, colors):
    out = image.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            rule = colors.get(group(px[x, y]))
            if rule:
                px[x, y] = shift(px[x, y], **rule)
    return out


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    house = house_of(sys.argv[1])
    folder = os.path.join(HERE, "timber_house")
    os.makedirs(folder, exist_ok=True)
    for variant, colors in enumerate(COLORS, start=1):
        recolor(house, colors).save(os.path.join(folder, "%d.png" % variant))
    shutil.copyfile(os.path.join(HERE, "big_house", "smoke.png"), os.path.join(folder, "smoke.png"))
    print("timber_house %dx%d" % house.size)


main()
