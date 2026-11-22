"""Monta as casas do tileset Village do Fantasy Dreamland Reborn (village-pack/01).

Uso: python -I make_village_houses.py <FDR_Village.png> [--preview <arquivo.png>]
(precisa do Pillow; roda de dentro de assets/props)

O pacote tem a casa em partes: os telhados (com a parede baixa) em 3 formatos e 3 cores, as
paredes altas, a porta no batente, as janelas e a chaminé. O script cola os tiles, sem pixel
novo, e emenda os formatos por colunas (a ala de uma casa com o frontão de outra). Grava
village_<formato>/1.png a 8.png, as 8 cores, e smoke.png (a fumaça da big_house), e imprime
o canto da fumaça e o bloqueio de cada formato. Com --preview, grava só a folha de conferência:
os formatos na cor 1, a casa grande espelhada e as 8 cores da Casa da vila.
"""

import colorsys
import os
import shutil
import sys
import unicodedata

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))

# A casa vermelha do pacote (telhado e parede baixa) por formato, e onde o mesmo telhado azul e
# o de ardósia ficam em relação a ela.
RED = {"wide": (256, 34, 384, 144), "long": (256, 146, 416, 256), "small": (432, 146, 496, 256)}
ROOF_AT = {
    "blue": {"wide": (0, 240), "long": (0, 208), "small": (0, 208)},
    "slate": {"wide": (128, 240), "long": (0, 288), "small": (0, 288)},
}
ROOF_HEIGHT = 78
# A parede alta de cada formato e onde ela fica em relação à casa vermelha (16 px mais funda).
BODY = {
    "wide": ((18, 256, 142, 320), (240, -160)),
    "long": ((2, 336, 158, 400), (256, -128)),
    "small": ((176, 256, 240, 320), (256, -48)),
}
BODY_CUT = 4
DOOR = (27, 134, 53, 160)
WINDOW = (464, 64, 480, 80)
ROUND_WINDOW = (464, 80, 480, 96)
CHIMNEY = (392, 129, 408, 160)

SHAPES = [
    ("cottage", "Casinha da vila"),
    ("house", "Casa da vila"),
    ("wing_house", "Casa de ala comprida"),
    ("manor", "Casa grande da vila"),
    ("longhouse", "Casa comprida da vila"),
    ("townhouse", "Sobrado da vila"),
    ("large_townhouse", "Sobrado grande da vila"),
    ("long_townhouse", "Sobrado comprido da vila"),
    ("twin_house", "Casa de dois frontões"),
    ("row_house", "Casa de três frontões"),
]


def crop(sheet, box):
    return sheet.crop(box)


def solid(image):
    """Só o pedaço ligado ao pé da casa (sem os tiles vizinhos que caem no retângulo)."""
    px = image.load()
    seed = (image.width // 2, image.height - 1)
    seen, queue = {seed}, [seed]
    while queue:
        x, y = queue.pop()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if (nx, ny) not in seen and 0 <= nx < image.width and 0 <= ny < image.height and px[nx, ny][3]:
                seen.add((nx, ny))
                queue.append((nx, ny))
    out = Image.new("RGBA", image.size)
    po = out.load()
    for x, y in seen:
        po[x, y] = px[x, y]
    return out


def base(sheet, kind, color, tall):
    """A casa de um formato, numa cor do pacote, com a parede baixa ou a alta."""
    x0, y0, x1, y1 = RED[kind]
    house = solid(crop(sheet, RED[kind]))
    if color != "red":
        dx, dy = ROOF_AT[color][kind]
        roof = Image.new("RGBA", house.size)
        roof.alpha_composite(crop(sheet, (x0 + dx, y0 + dy, x1 + dx, y0 + dy + ROOF_HEIGHT)))
        mask = house.split()[3]
        house.alpha_composite(Image.composite(roof, Image.new("RGBA", roof.size), mask))
    if tall:
        house = raise_walls(sheet, kind, house)
    if color != "red":
        house = paint(house, roof_colors(sheet, color))
    return house


def roof_colors(sheet, color):
    """Cada cor do telhado vermelho e a do mesmo pixel no telhado azul ou de ardósia."""
    votes = {}
    for kind, (x0, y0, x1, y1) in RED.items():
        dx, dy = ROOF_AT[color][kind]
        for y in range(y0, min(y1, sheet.height - dy)):
            for x in range(x0, min(x1, sheet.width - dx)):
                red, other = sheet.getpixel((x, y)), sheet.getpixel((x + dx, y + dy))
                if red[3] and other[3] and group(red) == "roof":
                    votes.setdefault(red, {}).setdefault(other, 0)
                    votes[red][other] += 1
    return {red: max(others, key=others.get) for red, others in votes.items()}


def paint(image, colors):
    out = image.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            if px[x, y] in colors:
                px[x, y] = colors[px[x, y]]
    return out


def raise_walls(sheet, kind, house):
    x0, y0, x1, y1 = RED[kind]
    (bx0, by0, bx1, by1), (ox, oy) = BODY[kind]
    top = by0 + oy - y0
    out = Image.new("RGBA", (house.width, by1 + oy - y0))
    hp, op = house.load(), out.load()
    for y in range(min(house.height, top + BODY_CUT)):
        for x in range(house.width):
            if hp[x, y][3]:
                op[x, y] = hp[x, y]
    body = crop(sheet, (bx0, by0, bx1, by1)).load()
    for y in range(by1 - by0):
        for x in range(bx1 - bx0):
            X, Y = bx0 + ox - x0 + x, top + y
            if body[x, y][3] and 0 <= X < out.width and (Y >= top + BODY_CUT or op[X, Y][3] == 0):
                op[X, Y] = body[x, y]
    return out


def group(color):
    if color[3] < 255:
        return None
    h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in color[:3]))
    h *= 360
    if s >= 0.55 and (h >= 340 or h < 14):
        return "roof"
    if s < 0.3 and v >= 0.8 and 15 <= h <= 45:
        return "plaster"
    return None


def shift(color, hue=None, sat=1.0, val=1.0):
    r, g, b, a = color
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    if hue is not None:
        h = ((hue + (((h * 360 + 180 - RED_HUE) % 360) - 180) * 0.5) % 360) / 360
    r, g, b = colorsys.hsv_to_rgb(h, min(1.0, s * sat), min(1.0, v * val))
    return (round(r * 255), round(g * 255), round(b * 255), a)


def recolor(image, rules):
    out = image.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            rule = rules.get(group(px[x, y]))
            if rule:
                px[x, y] = shift(px[x, y], **rule)
    return out


def splice(parts):
    """`parts`: (imagem, coluna inicial, coluna final), alinhadas pela borda de baixo."""
    height = max(image.height for image, _, _ in parts)
    width = sum(x1 - x0 for _, x0, x1 in parts)
    out = Image.new("RGBA", (width, height))
    at = 0
    for image, x0, x1 in parts:
        out.alpha_composite(image.crop((x0, 0, x1, image.height)), (at, height - image.height))
        at += x1 - x0
    return out


def add_rows(image, at, rows, band=16):
    """Repete as `band` linhas que acabam em `at` (parede lisa) até a casa crescer `rows`."""
    out = Image.new("RGBA", (image.width, image.height + rows))
    out.alpha_composite(image.crop((0, 0, image.width, at)))
    for start in range(0, rows, band):
        piece = image.crop((0, at - band, image.width, at - band + min(band, rows - start)))
        out.alpha_composite(piece, (0, at + start))
    out.alpha_composite(image.crop((0, at, image.width, image.height)), (0, at + rows))
    return out


def tile(sheet, box):
    piece = crop(sheet, box)
    return piece.crop(piece.getbbox())


def stamp(image, piece, center_x, bottom):
    image.alpha_composite(piece, (center_x - piece.width // 2, bottom - piece.height))


def is_wall(color):
    if color[3] < 255:
        return False
    h, s, v = colorsys.rgb_to_hsv(*(c / 255 for c in color[:3]))
    return s < 0.35 and v >= 0.85 and 15 <= h * 360 <= 45


def wall_span(image, x):
    """O reboco liso da coluna `x`, do beiral (ou da viga) até a faixa de pedra do pé."""
    px = image.load()
    y = image.height - 1
    while not is_wall(px[x, y]):
        y -= 1
    end = y + 1
    while y > 0 and is_wall(px[x, y - 1]):
        y -= 1
    return y, end


def centered(top, end, height):
    return top + (end - top + height + 1) // 2


def middle(image, x, y, width):
    """A coluna do meio da janela de `width` no reboco da linha `y`, entre os dois postes."""
    px = image.load()
    left = right = x
    while left > 0 and is_wall(px[left - 1, y]):
        left -= 1
    while right < image.width - 1 and is_wall(px[right + 1, y]):
        right += 1
    return left + (right + 1 - left - width) // 2 + width // 2


def roof_top(image, x):
    px = image.load()
    return min(y for y in range(image.height) if px[x, y][3])


# Por formato: as partes (formato, coluna inicial, final), a parede alta, as linhas a mais
# (o andar de cima), as portas, as janelas das alas, a janela em cima da porta, a janela
# redonda no frontão (colunas) e a coluna da esquerda da chaminé, na água esquerda.
FORMS = {
    "cottage": {"parts": [("small", 0, 64)], "tall": False, "doors": [32], "windows": [], "round": [], "chimney": 10},
    "house": {"parts": [("wide", 0, 64), ("small", 32, 64)], "tall": False, "doors": [64], "windows": [17], "round": [], "chimney": 42},
    "wing_house": {"parts": [("long", 0, 80), ("small", 32, 64)], "tall": True, "doors": [80], "windows": [25], "round": [80], "chimney": 58},
    "manor": {"parts": [("wide", 0, 128)], "tall": True, "doors": [64], "windows": [17, 111], "round": [64], "chimney": 42},
    "longhouse": {"parts": [("long", 0, 160)], "tall": True, "doors": [80], "windows": [25, 135], "round": [80], "chimney": 58},
    "townhouse": {"parts": [("small", 0, 64)], "tall": True, "rows": 20, "doors": [32], "windows": [], "upper": [32], "round": [32], "chimney": 10},
    "large_townhouse": {"parts": [("wide", 0, 128)], "tall": True, "rows": 20, "doors": [64], "windows": [17, 111], "upper": [64], "round": [64], "chimney": 42},
    "long_townhouse": {"parts": [("long", 0, 160)], "tall": True, "rows": 20, "doors": [80], "windows": [25, 135], "upper": [80], "round": [80], "chimney": 58},
    "twin_house": {"parts": [("small", 0, 32), ("long", 80, 128), ("long", 32, 80), ("small", 32, 64)], "tall": True, "doors": [32, 128], "windows": [80], "round": [32, 128], "chimney": 104},
    "row_house": {"parts": [("small", 0, 32), ("long", 80, 128), ("long", 32, 128), ("long", 32, 80), ("small", 32, 64)], "tall": True, "doors": [32, 128, 224], "windows": [80, 176], "round": [32, 128, 224], "chimney": 200},
}
ROUND_BOTTOM = 66
# A distância entre o pé da janela de baixo e o da de cima, nas alas do sobrado.
WINDOW_STEP = 24
# A boca da chaminé fica estas linhas abaixo do topo dela, e a fumaça da big_house sai do
# ponto (21, 38) do quadro de 48x48.
MOUTH_DEPTH = 2
SMOKE_FROM = (21, 38)
# A emenda do andar de cima: a faixa de parede lisa que acaba esta altura acima do pé.
FLOOR_SEAM = 26
RED_HUE = 2
# Por variante: a cor do pacote e a repintura (`hue` põe o telhado vermelho num matiz; `sat` e
# `val` multiplicam).
COLORS = [
    ("red", {}),
    ("blue", {}),
    ("red", {"roof": {"hue": 105, "sat": 0.7, "val": 0.95}}),
    ("red", {"roof": {"hue": 28, "sat": 0.6, "val": 0.8}, "plaster": {"sat": 0.35, "val": 1.04}}),
    ("slate", {}),
    ("red", {"roof": {"hue": 285, "sat": 0.6}}),
    ("red", {"roof": {"hue": 178, "sat": 0.65, "val": 0.95}}),
    ("red", {"roof": {"hue": 24, "sat": 1.0, "val": 1.1}}),
]


def shape(sheet, name, color):
    form = FORMS[name]
    bases = {kind: base(sheet, kind, color, form["tall"]) for kind in RED}
    house = splice([(bases[kind], x0, x1) for kind, x0, x1 in form["parts"]])
    tops = [roof_top(house, x) for x in range(house.width)]
    rows = form.get("rows", 0)
    if rows:
        house = add_rows(house, house.height - FLOOR_SEAM, rows)
    bottom = house.height
    door, window, round_window = tile(sheet, DOOR), tile(sheet, WINDOW), tile(sheet, ROUND_WINDOW)
    spans = {x: wall_span(house, x) for x in form["windows"] + form.get("upper", [])}
    for x in form["doors"]:
        stamp(house, door, x, bottom)
    for column in form["windows"]:
        top, end = spans[column]
        x = middle(house, column, (top + end) // 2, window.width)
        if rows:
            low = centered(top, end, window.height + WINDOW_STEP)
            stamp(house, window, x, low)
            stamp(house, window, x, low - WINDOW_STEP)
        else:
            stamp(house, window, x, centered(top, end, window.height))
    for x in form.get("upper", []):
        stamp(house, window, x, centered(spans[x][0], bottom - door.height, window.height))
    for x in form["round"]:
        stamp(house, round_window, x, tops[x] + ROUND_BOTTOM)
    chimney = tile(sheet, CHIMNEY)
    left = form["chimney"]
    top = tops[left] + 8 - chimney.height + 1
    house.alpha_composite(chimney, (left, top))
    house.info["mouth"] = (left + chimney.width // 2, top + MOUTH_DEPTH)
    return house


def variants(sheet, name):
    return [recolor(shape(sheet, name, color), rules) for color, rules in COLORS]


def preview(sheet, path):
    tamer = Image.open(os.path.join(HERE, "..", "tamer", "bodies", "male", "idle.png")).convert("RGBA").crop((0, 0, 32, 32))
    tamer = tamer.crop(tamer.getbbox())
    forms = [("%d. %s" % (index, label), shape(sheet, slug, "red")) for index, (slug, label) in enumerate(SHAPES, start=1)]
    forms.append(("Casa grande espelhada", shape(sheet, "manor", "red").transpose(Image.FLIP_LEFT_RIGHT)))
    forms.extend(("Cor %d" % index, art) for index, art in enumerate(variants(sheet, "house"), start=1))
    pad, per_row = 16, 4
    rows = [forms[i:i + per_row] for i in range(0, len(forms), per_row)]
    cell = max(form.width for _, form in forms) + tamer.width + pad * 2
    row_height = max(form.height for _, form in forms) + 36
    width, height = cell * per_row, row_height * len(rows)
    grass = crop(sheet, (16, 0, 48, 16))
    out = Image.new("RGBA", (width, height))
    for x in range(0, width, grass.width):
        for y in range(0, height, grass.height):
            out.alpha_composite(grass, (x, y))
    draw = ImageDraw.Draw(out)
    for r, row in enumerate(rows):
        ground = (r + 1) * row_height - 24
        for c, (label, form) in enumerate(row):
            at = c * cell + pad
            out.alpha_composite(form, (at, ground - form.height))
            out.alpha_composite(tamer, (at + form.width + 4, ground - tamer.height))
            plain = unicodedata.normalize("NFKD", label).encode("ascii", "ignore").decode()
            draw.text((at, ground + 6), plain, fill=(255, 255, 255, 255))
    out.resize((out.width * 2, out.height * 2), Image.NEAREST).save(path)


def main():
    args = sys.argv[1:]
    if len(args) not in (1, 3) or (len(args) == 3 and args[1] != "--preview"):
        sys.exit(__doc__)
    sheet = Image.open(args[0]).convert("RGBA")
    if len(args) == 3:
        preview(sheet, args[2])
        return
    for slug, label in SHAPES:
        folder = os.path.join(HERE, "village_" + slug)
        os.makedirs(folder, exist_ok=True)
        arts = variants(sheet, slug)
        for index, art in enumerate(arts, start=1):
            art.save(os.path.join(folder, "%d.png" % index))
        shutil.copyfile(os.path.join(HERE, "big_house", "smoke.png"), os.path.join(folder, "smoke.png"))
        art = shape(sheet, slug, "red")
        mouth_x, mouth_y = art.info["mouth"]
        px = art.load()
        columns = [x for x in range(art.width) if any(px[x, y][3] for y in range(art.height - 20, art.height))]
        foot = art.width // 2
        print("village_%s %dx%d fumaca (%d, %d) bloqueio (%d, -2) a (%d, -14)" % (
            slug, art.width, art.height, mouth_x - SMOKE_FROM[0] - foot, mouth_y - SMOKE_FROM[1] - art.height,
            columns[0] + 2 - foot, columns[-1] - 2 - foot))


main()
