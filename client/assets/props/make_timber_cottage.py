"""Monta a casinha enxaimel a partir da imagem do dono (timber-cottage/01).

Uso: python -I make_timber_cottage.py   (precisa do Pillow e do numpy; roda de dentro de assets/props)

A imagem (art-source/timber_cottage/reference.png) é a pixel art ampliada 5,12 vezes e suavizada,
com dezenas de tons. O script lê a cor do meio de cada pixel da arte, junta as cores parecidas,
tira o fundo branco, dá a cada cor um material (telha, madeira, reboco, pedra, vidro), troca os
tons de cada material pelos da Casa grande na mesma proporção de claro e escuro, pinta o contorno
preto com o escuro do material vizinho, põe a sombra da Casa grande e grava timber_cottage/1.png a
8.png, as 8 cores da Casa grande, pelos mesmos grupos e regras do make_houses.py.
"""

import colorsys
import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.join(HERE, "..", "..", "..", "art-source", "timber_cottage", "reference.png")
SCALE = 5.12
# A primeira borda de pixel da arte, na imagem.
EDGE = (203.79, 28.22)
SAME = 14
# A janela, na arte recortada: a moldura escura dela tem o vermelho da telha.
WINDOW = (78, 90, 99, 110)
SHADOW = (53, 53, 43, 89)
# A arte da imagem fica grande perto da Casa grande: 70% põe a porta na altura da dela.
SIZE = 0.7
DARK_VOTE = 2.5
# Os tons de cada material na Casa grande (big_house/1.png), do claro ao escuro, com quantos
# pixels cada um tem lá: a arte nova repete a proporção.
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
OUTLINE = {"roof": "3f1428", "wood": "482a2a", "stone": "28282e", "plaster": "423432", "glass": "482a2a"}
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
    return palette, index[rows.min() : rows.max() + 1, cols.min() : cols.max() + 1]


def material(color):
    h, s, v = colorsys.rgb_to_hsv(*(np.asarray(color) / 255))
    h *= 360
    if v < 0.13:
        return "outline"
    if 195 <= h <= 240 and s >= 0.15:
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


def materials(palette, index):
    rows, cols = index.shape
    mat = np.full(index.shape, "", object)
    for j, i in zip(*np.nonzero(index >= 0)):
        mat[j, i] = material(palette[index[j, i]])
        inside = WINDOW[0] <= i <= WINDOW[2] and WINDOW[1] <= j <= WINDOW[3]
        if mat[j, i] == "roof" and inside:
            mat[j, i] = "wood"
        if mat[j, i] == "glass" and not inside:
            mat[j, i] = "stone"
    # O vermelho escuro solto fora do telhado (nas vigas e na borda do reboco) e o cinza solto no
    # alto (a pedra e a maçaneta ficam embaixo) viram o vizinho.
    for j, i in zip(*np.nonzero((mat == "roof") | ((mat == "stone") & (np.arange(rows) < rows * 0.6)[:, None]))):
        near = [mat[y, x] for y in range(j - 2, j + 3) for x in range(i - 2, i + 3)
                if 0 <= y < rows and 0 <= x < cols and mat[y, x] not in ("", "outline", "dark")]
        if near.count(mat[j, i]) * 10 < len(near) * 4:
            mat[j, i] = "dark"
    # Os escuros que podem ser de telha ou de madeira ficam com o material da maioria em volta
    # (o vidro não conta: a cruz da janela é de madeira).
    while (mat == "dark").any():
        changed = mat.copy()
        for j, i in zip(*np.nonzero(mat == "dark")):
            near = [mat[y, x] for y in range(j - 1, j + 2) for x in range(i - 1, i + 2)
                    if 0 <= y < rows and 0 <= x < cols and mat[y, x] not in ("", "dark", "outline", "glass")]
            if near:
                changed[j, i] = max(set(near), key=near.count)
        if (changed == mat).all():
            changed[mat == "dark"] = "wood"
        mat = changed
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
        else:
            color = tone[mat[j, i], index[j, i]]
        po[i + 1, j] = tuple(int(color[k : k + 2], 16) for k in (0, 2, 4)) + (255,)
    # A sombra da Casa grande do lado das paredes, abaixo do beiral, e nas 2 linhas de baixo,
    # menos sob a porta (a madeira que encosta no chão no meio).
    eaves = max(j for j, i in zip(*np.nonzero(mat == "roof")))
    for y in range(eaves + 2, rows):
        row = [x for x in range(cols + 2) if po[x, y][3] == 255]
        if row:
            for x in (row[0] - 1, row[-1] + 1):
                if not po[x, y][3]:
                    po[x, y] = SHADOW
    door = [i for i in range(cols) if mat[rows - 3, i] == "wood" and abs(i - cols / 2) < 20]
    for y in (rows, rows + 1):
        for x in range(1, cols + 1):
            if po[x, rows - 1][3] and not min(door) + 1 <= x - 1 <= max(door) - 1:
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


def shrunk(palette, index, mat):
    """Reduz a arte para SIZE: cada pixel novo fica com a cor que mais cobre a área dele, com o
    contorno e os escuros valendo mais, para os traços de 1 px não sumirem."""
    rows, cols = index.shape
    height, width = round(rows * SIZE), round(cols * SIZE)
    small_index = np.full((height, width), -1)
    small_mat = np.full((height, width), "", object)
    for ty in range(height):
        y0, y1 = ty / SIZE, (ty + 1) / SIZE
        for tx in range(width):
            x0, x1 = tx / SIZE, (tx + 1) / SIZE
            votes = {}
            for j in range(int(y0), min(int(np.ceil(y1)), rows)):
                for i in range(int(x0), min(int(np.ceil(x1)), cols)):
                    area = (min(y1, j + 1) - max(y0, j)) * (min(x1, i + 1) - max(x0, i))
                    k = index[j, i]
                    dark = k >= 0 and (mat[j, i] == "outline" or palette[k] @ (0.299, 0.587, 0.114) < 70)
                    key = (k, mat[j, i])
                    votes[key] = votes.get(key, 0) + area * (DARK_VOTE if dark else 1)
            small_index[ty, tx], small_mat[ty, tx] = max(votes, key=votes.get)
    return small_index, small_mat


def main():
    palette, index = clustered(sampled())
    index, mat = shrunk(palette, index, materials(palette, index))
    house = painted(palette, index, mat)
    folder = os.path.join(HERE, "timber_cottage")
    os.makedirs(folder, exist_ok=True)
    for variant, colors in enumerate(COLORS, start=1):
        recolor(house, colors).save(os.path.join(folder, "%d.png" % variant))
    glass = np.nonzero(mat == "glass")
    foot = (house.width // 2, house.height)
    print("timber_cottage %dx%d, janela em %d,%d do pé" % (
        house.size + (round(glass[1].mean()) + 1 - foot[0], round(glass[0].mean()) - foot[1])))


main()
