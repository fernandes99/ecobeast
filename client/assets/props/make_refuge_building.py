"""Monta o prédio do Refúgio a partir da imagem do dono (refuge-art/01).

Uso: python -I make_refuge_building.py   (precisa do Pillow e do numpy; roda de dentro de assets/props)

A imagem (art-source/refuge_building/reference.png) é a pixel art ampliada 5,12 vezes e suavizada,
como a da Casinha enxaimel. O script lê a cor do meio de cada pixel da arte, junta as cores
parecidas, tira o fundo branco e a fumaça da chaminé (a do jogo é a animada da Casa grande), dá a
cada cor um material, troca os tons de cada material pelos da Casa grande na mesma proporção de
claro e escuro, pinta o contorno preto com o escuro do material vizinho, põe a sombra da Casa grande
e grava refuge_building/1.png a 8.png, as 8 cores da Casa grande, com a smoke.png da Casa grande. A cruz vermelha, as flores, as
plantas da estufa e as lanternas ficam com as cores da imagem.
"""

import colorsys
import os
import shutil

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.join(HERE, "..", "..", "..", "art-source", "refuge_building", "reference.png")
SCALE = 5.12
# A primeira borda de pixel da arte, na imagem.
EDGE = (5.05, 3.6)
SAME = 14
# Na grade da imagem: a fumaça desenhada acima da chaminé sai.
SMOKE = (50, 0, 76, 15)
# Na grade da imagem: as placas com a cruz, onde o vermelho não é telha, e as floreiras, as
# lanternas e as plantas da estufa, que ficam com as cores da imagem.
KEEP_RED = [(92, 92, 106, 106), (131, 108, 144, 122)]
KEEP = [(24, 81, 36, 86), (47, 81, 58, 86), (141, 81, 152, 87), (163, 81, 174, 87),
        (83, 108, 87, 116), (112, 108, 116, 116), (46, 98, 63, 119)]
SHADOW = (53, 53, 43, 89)
RAMPS = {
    "roof": [("bb4f3c", 376), ("9e3931", 1039), ("8a2a2a", 1073), ("741c25", 975), ("6d1924", 1176),
             ("5f1a28", 571), ("59192d", 299), ("53182e", 205), ("3f1428", 210)],
    "wood": [("c48e5e", 108), ("ab7757", 335), ("94614a", 656), ("82503f", 494), ("6c4036", 303),
             ("5d3731", 16), ("482a2a", 147)],
    "plaster": [("f6ebc9", 7), ("e2d5b9", 712), ("c7b39b", 171), ("c1ab93", 380), ("af9a87", 92),
                ("917d72", 114)],
    "stone": [("7f9ca8", 6), ("768996", 46), ("6c7a86", 302), ("646e79", 833), ("565a65", 706),
              ("4f525d", 335), ("464752", 98), ("393a42", 34)],
    "glass": [("8ab1db", 72), ("7b85c3", 257), ("63609f", 171)],
}
OUTLINE = {"roof": "3f1428", "wood": "482a2a", "stone": "28282e", "plaster": "423432", "glass": "482a2a",
           "keep": "482a2a"}
# Iguais às do make_houses.py, para as casas combinarem na vila.
ROOF = {"3f1428", "53182e", "59192d", "5f1a28", "6d1924", "741c25", "8a2a2a", "9e3931", "bb4f3c"}
STONE = {"28282e", "393a42", "3c3d46", "464752", "474853", "4f525d", "565a65", "646e79", "6c7a86", "768996", "7f9ca8"}
CREAM = {"e2d5b9", "f6ebc9", "c7b39b", "c1ab93", "af9a87", "917d72", "938073", "9a8479"}
COLORS = [
    {},
    {"roof": {"hue": 215, "sat": 0.85}},
    {"roof": {"hue": 105, "sat": 0.7, "val": 0.95}, "stone": {"turn": -175, "sat": 1.8, "val": 1.12}},
    {"roof": {"hue": 28, "sat": 0.75, "val": 1.05}, "cream": {"sat": 0.25, "val": 1.06}},
    {"roof": {"hue": 225, "sat": 0.25, "val": 0.95}, "stone": {"val": 0.82}},
    {"roof": {"hue": 285, "sat": 0.6}},
    {"roof": {"hue": 178, "sat": 0.65, "val": 0.95}, "cream": {"turn": 170, "sat": 0.8}},
    {"roof": {"hue": 22, "sat": 1.0, "val": 1.12}, "stone": {"turn": -190, "sat": 1.4}},
]


def sampled():
    src = np.asarray(Image.open(SOURCE).convert("RGB")).astype(float)
    cols = int((src.shape[1] - EDGE[0]) // SCALE)
    rows = int((src.shape[0] - EDGE[1]) // SCALE)
    grid = np.zeros((rows, cols, 3))
    for j in range(rows):
        for i in range(cols):
            x, y = int(EDGE[0] + (i + 0.5) * SCALE), int(EDGE[1] + (j + 0.5) * SCALE)
            grid[j, i] = np.median(src[y - 1 : y + 2, x - 1 : x + 2].reshape(-1, 3), axis=0)
    grid[SMOKE[1] : SMOKE[3] + 1, SMOKE[0] : SMOKE[2] + 1] = 255
    return grid


def clustered(grid):
    """As cores juntadas e, para cada pixel, o índice da cor dele (-1 no fundo), recortado."""
    solid = grid.sum(axis=2) < 690
    groups = []
    for color in grid[solid]:
        for members in groups:
            if np.abs(members[0] - color).max() < SAME:
                members.append(color)
                break
        else:
            groups.append([color])
    palette = np.array([np.mean(members, axis=0) for members in groups]).round()
    index = np.full(solid.shape, -1)
    for j, i in zip(*np.nonzero(solid)):
        index[j, i] = np.argmin(((palette - grid[j, i]) ** 2).sum(axis=1))
    rows, cols = np.nonzero(index >= 0)
    origin = (cols.min(), rows.min())
    return palette, index[rows.min() : rows.max() + 1, cols.min() : cols.max() + 1], origin


def material(color):
    h, s, v = colorsys.rgb_to_hsv(*(np.asarray(color) / 255))
    h *= 360
    if v < 0.13:
        return "outline"
    if s >= 0.3 and (70 <= h <= 170 or 280 <= h < 335):
        return "keep"
    if s >= 0.45 and v >= 0.7 and 40 <= h <= 65:
        return "keep"
    if 180 <= h <= 240 and s >= 0.15:
        return "glass"
    if s < 0.18:
        return "stone"
    if v >= 0.55 and s <= 0.31:
        return "plaster"
    if (h >= 335 or h <= 12) and s >= 0.55:
        return "roof"
    if v < 0.40 and s < 0.5:
        return "dark"
    return "wood"


def inside(i, j, boxes):
    return any(x0 <= i <= x1 and y0 <= j <= y1 for x0, y0, x1, y1 in boxes)


def materials(palette, index, origin):
    rows, cols = index.shape
    mat = np.full(index.shape, "", object)
    for j, i in zip(*np.nonzero(index >= 0)):
        mat[j, i] = material(palette[index[j, i]])
        at = (i + origin[0], j + origin[1])
        if mat[j, i] != "outline" and (inside(*at, KEEP) or mat[j, i] == "roof" and inside(*at, KEEP_RED)):
            mat[j, i] = "keep"
    # O vermelho escuro solto fora do telhado (nas vigas e na borda do reboco) vira o vizinho.
    for j, i in zip(*np.nonzero(mat == "roof")):
        near = [mat[y, x] for y in range(j - 2, j + 3) for x in range(i - 2, i + 3)
                if 0 <= y < rows and 0 <= x < cols and mat[y, x] not in ("", "outline", "dark")]
        if near.count(mat[j, i]) * 10 < len(near) * 4:
            mat[j, i] = "dark"
    # Os escuros que podem ser de telha ou de madeira ficam com o material da maioria em volta.
    while (mat == "dark").any():
        changed = mat.copy()
        for j, i in zip(*np.nonzero(mat == "dark")):
            near = [mat[y, x] for y in range(j - 1, j + 2) for x in range(i - 1, i + 2)
                    if 0 <= y < rows and 0 <= x < cols and mat[y, x] not in ("", "dark", "outline", "glass", "keep")]
            if near:
                changed[j, i] = max(set(near), key=near.count)
        if (changed == mat).all():
            changed[mat == "dark"] = "wood"
        mat = changed
    # A madeira solta no meio das telhas ficaria com a cor da madeira nos telhados de outra cor.
    loose = []
    for j, i in zip(*np.nonzero(mat == "wood")):
        near = [mat[y, x] for y in range(j - 1, j + 2) for x in range(i - 1, i + 2) if 0 <= y < rows and 0 <= x < cols]
        if near.count("roof") >= 5:
            loose.append((j, i))
    for j, i in loose:
        mat[j, i] = "roof"
    return mat


def tones(palette, index, mat):
    """Para cada material, cada cor da imagem vira o tom da Casa grande que está no mesmo ponto
    da escala de claro a escuro, contada em pixels."""
    out = {}
    for name, ramp in RAMPS.items():
        counts = {}
        for k in index[mat == name]:
            counts[k] = counts.get(k, 0) + 1
        if not counts:
            continue
        light = lambda k: palette[k] @ (0.299, 0.587, 0.114)
        order = sorted(counts, key=light, reverse=True)
        total = sum(counts.values())
        edges = np.cumsum([n for _, n in ramp]) / sum(n for _, n in ramp)
        seen = 0
        for k in order:
            middle = (seen + counts[k] / 2) / total
            seen += counts[k]
            out[name, k] = ramp[min(int(np.searchsorted(edges, middle)), len(ramp) - 1)][0]
    return out


def painted(palette, index, mat):
    rows, cols = index.shape
    tone = tones(palette, index, mat)
    out = Image.new("RGBA", (cols + 2, rows + 2))
    po = out.load()
    for j, i in zip(*np.nonzero(index >= 0)):
        if mat[j, i] == "outline":
            near = [mat[y, x] for y in range(j - 1, j + 2) for x in range(i - 1, i + 2)
                    if 0 <= y < rows and 0 <= x < cols and mat[y, x] not in ("", "outline")]
            color = OUTLINE[max(set(near), key=near.count)] if near else OUTLINE["wood"]
        elif mat[j, i] == "keep":
            color = "%02x%02x%02x" % tuple(int(c) for c in palette[index[j, i]])
        else:
            color = tone[mat[j, i], index[j, i]]
        po[i + 1, j] = tuple(int(color[k : k + 2], 16) for k in (0, 2, 4)) + (255,)
    # A sombra da Casa grande: 1 px do lado das paredes (onde a borda da linha não é telhado) e
    # 2 px abaixo do pé de cada coluna.
    for y in range(rows):
        row = [x for x in range(cols + 2) if po[x, y][3] == 255]
        if not row:
            continue
        for x, step in ((row[0], 1), (row[-1], -1)):
            wall = [mat[y, x - 1 + step * k] for k in range(1, 4) if 0 <= x - 1 + step * k < cols]
            if "roof" not in wall and not po[x - step, y][3]:
                po[x - step, y] = SHADOW
    for x in range(1, cols + 1):
        solid = [y for y in range(rows) if po[x, y][3] == 255]
        if solid:
            for y in (solid[-1] + 1, solid[-1] + 2):
                if not po[x, y][3]:
                    po[x, y] = SHADOW
    return out


def code(color):
    return "%02x%02x%02x" % color[:3]


def shift(color, hue=None, turn=0.0, sat=1.0, val=1.0):
    r, g, b, a = color
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    if hue is not None:
        h = ((hue + (((h * 360 + 180 - 355) % 360) - 180) * 0.5) % 360) / 360
    h = (h + turn / 360) % 1.0
    r, g, b = colorsys.hsv_to_rgb(h, min(1.0, s * sat), min(1.0, v * val))
    return (round(r * 255), round(g * 255), round(b * 255), a)


def recolor(image, colors):
    out = image.copy()
    px = out.load()
    groups = [(ROOF, colors.get("roof")), (STONE, colors.get("stone")), (CREAM, colors.get("cream"))]
    for y in range(out.height):
        for x in range(out.width):
            if px[x, y][3] < 255:
                continue
            for group, rule in groups:
                if rule and code(px[x, y]) in group:
                    px[x, y] = shift(px[x, y], **rule)
                    break
    return out


def main():
    palette, index, origin = clustered(sampled())
    mat = materials(palette, index, origin)
    house = painted(palette, index, mat)
    folder = os.path.join(HERE, "refuge_building")
    os.makedirs(folder, exist_ok=True)
    for variant, colors in enumerate(COLORS, start=1):
        recolor(house, colors).save(os.path.join(folder, "%d.png" % variant))
    shutil.copyfile(os.path.join(HERE, "big_house", "smoke.png"), os.path.join(folder, "smoke.png"))
    debug = os.environ.get("REFUGE_DEBUG")
    if debug:
        names = {"": (255, 255, 255), "outline": (0, 0, 0), "roof": (200, 40, 40), "wood": (140, 90, 40),
                 "plaster": (240, 230, 190), "stone": (120, 120, 130), "glass": (60, 120, 230), "keep": (40, 220, 80)}
        view = Image.new("RGB", (mat.shape[1], mat.shape[0]))
        for j in range(mat.shape[0]):
            for i in range(mat.shape[1]):
                view.putpixel((i, j), names[mat[j, i]])
        view.resize((view.width * 5, view.height * 5), Image.NEAREST).save(debug)
    print("refuge_building %dx%d" % house.size)


main()
