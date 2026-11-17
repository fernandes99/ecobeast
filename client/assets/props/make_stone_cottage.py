"""Monta a casinha de pedra a partir da imagem do dono (stone-cottage/01).

Uso: python -I make_stone_cottage.py   (precisa do Pillow e do numpy; roda de dentro de assets/props)

A imagem (art-source/stone_cottage/reference.png) é a pixel art ampliada uns 8,53 vezes e
suavizada. O script lê a cor do meio de cada pixel da arte, junta as cores parecidas, tira o
fundo branco e as sobras de fora do contorno preto, troca as cores pelas da Casa grande (o
contorno preto vira o escuro da parte vizinha), põe a sombra dela e grava stone_cottage/1.png a
8.png, as 8 cores da Casa grande, pelos mesmos grupos e regras do make_houses.py.
"""

import colorsys
import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.join(HERE, "..", "..", "..", "art-source", "stone_cottage", "reference.png")
SCALE = 8.53
# A primeira borda de pixel da arte, na imagem.
EDGE = (306.9, 5.8)
SAME = 16
DOOR = (17, 45, 31, 64)
RIDGE = (22, 25, 28)
SHADOW = (53, 53, 43, 89)
# A cor de cada pixel da imagem, pelo papel dele, vira a da Casa grande (big_house/1.png).
TONES = {
    "roof_left": {"682425": "9e3931", "944636": "bb4f3c", "97563e": "bb4f3c", "7e2f2a": "bb4f3c",
                  "4e1b22": "8a2a2a", "562f30": "6d1924", "3b161d": "59192d", "271015": "3f1428"},
    "roof_right": {"682425": "741c25", "944636": "8a2a2a", "97563e": "8a2a2a", "7e2f2a": "8a2a2a",
                   "4e1b22": "5f1a28", "562f30": "53182e", "3b161d": "53182e", "271015": "3f1428"},
    "ridge": {"97563e": "ab7757", "6f4231": "82503f", "682425": "9e3931", "4e1b22": "5f1a28"},
    "stone": {"5c6b75": "646e79", "404d5f": "4f525d", "72878d": "6c7a86", "34394d": "393a42",
              "323342": "393a42", "222532": "393a42", "545258": "565a65"},
    "base": {"adaeb1": "e2d5b9", "818a8a": "c7b39b", "545258": "af9a87"},
    "door": {"8a5a3d": "94614a", "6f4231": "6c4036", "562f30": "82503f", "50393e": "482a2a",
             "969899": "e2d5b9", "545258": "5d3731"},
}
OUTLINE = {"door": "482a2a", "base": "423432", "roof": "3f1428", "stone": "28282e"}
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
            grid[j, i] = np.median(src[y - 2 : y + 2, x - 2 : x + 2].reshape(-1, 3), axis=0)
    return grid


def cleaned(grid):
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
    rows, cols = solid.shape
    out = np.zeros((rows, cols, 4), np.uint8)
    for j, i in zip(*np.nonzero(solid)):
        out[j, i, :3] = palette[np.argmin(((palette - grid[j, i]) ** 2).sum(axis=1))]
        out[j, i, 3] = 255
    # O que não é contorno e encosta no fundo, por fora do contorno, é sobra da suavização.
    dark = out[:, :, :3].astype(int).sum(axis=2) < 90
    seen = np.zeros_like(solid)
    stack = [(j, i) for j in range(rows) for i in range(cols) if j in (0, rows - 1) or i in (0, cols - 1)]
    while stack:
        j, i = stack.pop()
        if not (0 <= j < rows and 0 <= i < cols) or seen[j, i] or (out[j, i, 3] and dark[j, i]):
            continue
        seen[j, i] = True
        out[j, i] = 0
        stack += [(j + 1, i), (j - 1, i), (j, i + 1), (j, i - 1)]
    image = Image.fromarray(out)
    return image.crop(image.getbbox())


def code(color):
    return "%02x%02x%02x" % color[:3]


def role(x, y, value):
    if DOOR[0] <= x <= DOOR[2] and DOOR[1] <= y <= DOOR[3]:
        # A maçaneta tem o cinza da pedra; o resto da pedra na caixa da porta é o arco em volta.
        if value not in TONES["stone"] or (value == "545258" and y >= 50):
            return "door"
    if value in ("adaeb1", "818a8a") or (value == "545258" and y >= 62):
        return "base"
    if value in TONES["stone"]:
        return "stone"
    if RIDGE[0] <= x <= RIDGE[1] and y <= RIDGE[2]:
        return "ridge"
    return "roof_left" if x < RIDGE[0] else "roof_right"


def restyled(image):
    """Troca o contorno preto pelo escuro da cor vizinha e as cores pelas da Casa grande, e põe a
    sombra translúcida da Casa grande do lado das paredes e embaixo, menos sob a porta."""
    px = image.load()
    w, h = image.size
    roles = {}
    for y in range(h):
        for x in range(w):
            if px[x, y][3] and sum(px[x, y][:3]) >= 60:
                roles[x, y] = role(x, y, code(px[x, y]))
    out = Image.new("RGBA", (w + 2, h + 2))
    po = out.load()
    for y in range(h):
        for x in range(w):
            if not px[x, y][3]:
                continue
            if (x, y) in roles:
                tone = TONES[roles[x, y]].get(code(px[x, y]))
                if roles[x, y] == "ridge" and x == RIDGE[0] and tone == "ab7757":
                    tone = "c48e5e"
                if tone is None:
                    raise SystemExit("cor sem tom: %s em %d,%d (%s)" % (code(px[x, y]), x, y, roles[x, y]))
            else:
                near = {roles.get((x + dx, y + dy), "")[:4].rstrip("_") for dx in (-1, 0, 1) for dy in (-1, 0, 1)}
                near = {"roof" if n in ("roof", "ridg") else n for n in near}
                tone = next((OUTLINE[r] for r in OUTLINE if r in near), OUTLINE["roof"])
            po[x + 1, y] = tuple(int(tone[i : i + 2], 16) for i in (0, 2, 4)) + (255,)
    eaves = max(y for (_, y), r in roles.items() if r.startswith("roof"))
    for y in range(eaves + 2, h):
        row = [x for x in range(w + 2) if po[x, y][3] == 255]
        if row:
            for x in (row[0] - 1, row[-1] + 1):
                if not po[x, y][3]:
                    po[x, y] = SHADOW
    for y in (h, h + 1):
        for x in range(1, w + 1):
            if not DOOR[0] + 1 <= x - 1 <= DOOR[2] - 1 and po[x, h - 1][3]:
                po[x, y] = SHADOW
    return out


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
    house = restyled(cleaned(sampled()))
    folder = os.path.join(HERE, "stone_cottage")
    os.makedirs(folder, exist_ok=True)
    for variant, colors in enumerate(COLORS, start=1):
        recolor(house, colors).save(os.path.join(folder, "%d.png" % variant))
    print("stone_cottage %dx%d" % house.size)


main()
