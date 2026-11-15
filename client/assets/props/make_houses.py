"""Recorta as casas e a fumaça da chaminé do pacote Main Characters Home (home-pack/01 e 03).

Uso: python -I make_houses.py <pasta PNG do pacote>   (precisa do Pillow; roda de dentro de assets/props)

Grava, sem desenhar pixel novo, três formatos em 8 cores (variantes 1 a 8):
- big_house: a casa de exterior.png;
- small_house: a casa sem a ala direita e sem a terceira janela, com a porta no meio;
- small_townhouse: a pequena com um andar de pedra a mais, de janelas.
Cada pasta ganha smoke.png, os 6 quadros de 48x48 de Smoke_animation.png só com os pixels da
fumaça (o que é igual à casa embaixo sai). Imprime onde fica o canto do quadro em relação ao
pé de cada formato, o HexMapView.PROP_SMOKE.
"""

import colorsys
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
HOUSE_SEED = (80, 60)
HOUSE_BOTTOM = 127
FRAME = 48
FRAMES = 6
SMOKE_AT = (16, -16)

ROOF = {"3f1428", "53182e", "59192d", "5f1a28", "6d1924", "741c25", "8a2a2a", "9e3931", "bb4f3c"}
STONE = {"28282e", "393a42", "3c3d46", "464752", "474853", "4f525d", "565a65", "646e79", "6c7a86", "768996", "7f9ca8"}
CREAM = {"e2d5b9", "f6ebc9", "c7b39b", "c1ab93", "af9a87", "917d72", "938073", "9a8479"}
# Por variante: a cor do telhado, da pedra e do frontão. `hue` põe o grupo num matiz (o
# vermelho de 355° vira ele); `turn` gira o matiz; `sat` e `val` multiplicam.
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


def code(color):
    return "%02x%02x%02x" % color[:3]


def house_of(sheet):
    pixels = sheet.load()
    seen = {HOUSE_SEED}
    queue = [HOUSE_SEED]
    while queue:
        x, y = queue.pop()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if (nx, ny) in seen or not (0 <= nx < sheet.width and 0 <= ny <= HOUSE_BOTTOM):
                continue
            if pixels[nx, ny][3] > 0:
                seen.add((nx, ny))
                queue.append((nx, ny))
    left = min(x for x, _ in seen)
    top = min(y for _, y in seen)
    art = Image.new("RGBA", (max(x for x, _ in seen) - left + 1, max(y for _, y in seen) - top + 1))
    for x, y in seen:
        art.putpixel((x - left, y - top), pixels[x, y])
    return art, (left, top), seen


class Shapes:
    """Remonta a casa por colunas: o telhado de uma coluna e a parede de outra."""

    def __init__(self, house):
        self.house = house
        self.px = house.load()
        self.width, self.height = house.size
        # A parede começa na primeira pedra abaixo do beiral; a coluna sem pedra é só telhado.
        self.cut = [next((y for y in range(84, self.height) if self.px[x, y][3] and code(self.px[x, y]) in STONE), self.height)
                    for x in range(self.width)]

    def wall_pixel(self, column, y, eave):
        if y < self.cut[column]:
            y = self.cut[column] + (y - eave) % 8
        return self.px[column, y] if y < self.height else (0, 0, 0, 0)

    def build(self, roof, lower, upper=None, rows=0, split=100):
        """`roof[X]` é (coluna, quanto sobe); `lower` e `upper` são as colunas da parede de baixo e
        da de cima. Com `rows`, entra um andar de `rows` linhas a partir da linha `split`."""
        upper = upper or lower
        out = Image.new("RGBA", (len(roof), self.height + rows))
        po = out.load()
        for X, ((column, rise), low, high) in enumerate(zip(roof, lower, upper)):
            eave = self.cut[column] - rise
            for y in range(max(eave, 0), split + rows if rows else self.height):
                value = self.wall_pixel(high, y, eave)
                if value[3]:
                    po[X, y] = value
            if rows:
                for y in range(split, self.height):
                    if self.px[low, y][3]:
                        po[X, y + rows] = self.px[low, y]
            for y in range(self.cut[column]):
                if self.px[column, y][3] and 0 <= y - rise:
                    po[X, y - rise] = self.px[column, y]
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
            value = px[x, y]
            if value[3] == 0:
                continue
            for group, rule in groups:
                if rule and code(value) in group:
                    px[x, y] = shift(value, **rule)
                    break
    return out


def smoke_of(sheet, smoke, house):
    pixels = sheet.load()
    frames = smoke.load()
    puffs = Image.new("RGBA", (FRAME * FRAMES, FRAME))
    for frame in range(FRAMES):
        for y in range(FRAME):
            for x in range(FRAME):
                value = frames[frame * FRAME + x, y]
                if value[3] == 0:
                    continue
                at = (SMOKE_AT[0] + x, SMOKE_AT[1] + y)
                if at in house and pixels[at] == value:
                    continue
                puffs.putpixel((frame * FRAME + x, y), value)
    return puffs


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    sheet = Image.open(os.path.join(sys.argv[1], "exterior.png")).convert("RGBA")
    house, (left, top), pixels = house_of(sheet)
    puffs = smoke_of(sheet, Image.open(os.path.join(sys.argv[1], "Smoke_animation.png")).convert("RGBA"), pixels)
    shapes = Shapes(house)
    width = shapes.width
    # A pequena: o telhado sem 30 colunas da ala (ele sobe 1 px a cada 3), e a parede com a
    # janela 1, a 2, a porta, a 3 e o canto.
    small_roof = [(x, 0) for x in range(96)] + [(x, 10) for x in range(126, width)]
    small_wall = [*range(0, 30), *range(36, 56), *range(87, 108), *range(62, 82), *range(108, 113), *range(126, width)]
    small_upper = [*range(0, 30), *range(36, 56), *range(8, 29), *range(62, 82), *range(108, 113), *range(126, width)]
    forms = {
        "big_house": house,
        "small_house": shapes.build(small_roof, small_wall),
        "small_townhouse": shapes.build(small_roof, small_wall, small_upper, rows=20),
    }
    for slug, form in forms.items():
        folder = os.path.join(HERE, slug)
        os.makedirs(folder, exist_ok=True)
        for variant, colors in enumerate(COLORS, start=1):
            recolor(form, colors).save(os.path.join(folder, "%d.png" % variant))
        puffs.save(os.path.join(folder, "smoke.png"))
        print("%s %dx%d: quadro da fumaça em (%d, %d) do pé" % (
            slug, form.width, form.height, SMOKE_AT[0] - left - form.width // 2, SMOKE_AT[1] - top - form.height))


main()
