"""Recorta os objetos do tileset Village do Fantasy Dreamland Reborn (village-pack/02).

Uso: python -I make_village_objects.py <FDR_Village.png> [--sheet <arquivo.png>]
(precisa do Pillow; roda de dentro de assets/props)

Cada variante é um retângulo da folha (ou dois colados: a estátua na fonte grande e o ícone na
placa do braço), recortada pelos pixels, sem mudar nenhum. Grava village_<objeto>/<n>.png e
imprime a caixa da base de cada variante que bloqueia, a partir do pé. Com --sheet, grava só
uma folha de conferência com todas as variantes numeradas.
"""

import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))

# Os 8 ícones são só o corpo da placa (16x10), sem a tampa: entram por cima do corpo da placa
# lisa do braço, em (16, 16) do braço.
ICONS = [(224 + 16 * (i % 2), 320 + 16 * (i // 2)) for i in range(8)]
ICON_SIZE = (16, 10)
ICON_AT = (16, 16)
SIGN_ARM = (192, 320, 224, 352)
CROSS = 6
# O + da placa do Refúgio: gravado (o do pacote), vermelho (o da cruz do prédio do Refúgio),
# branco e verde. Só os pixels claros do + mudam de cor.
CROSS_BOX = (4, 2, 12, 6)
CROSS_COLORS = [None, (206, 52, 48, 255), (244, 236, 220, 255), (92, 186, 84, 255)]
STATUE = (68, 423, 92, 456)

# slug, nome, variantes: cada uma é um retângulo (x0, y0, x1, y1) da folha ou uma função; o
# quarto campo é a altura da base que bloqueia (None: não bloqueia; "all": a arte toda).
OBJECTS = [
    ("village_fountain", "Fonte da vila", [((0, 400, 64, 464), "all"), ("statue_fountain", "all"), ((96, 416, 144, 464), "all"), ((144, 408, 192, 464), "all")]),
    ("village_well", "Poço de pedra", [((130, 130, 158, 158), "all"), ((162, 130, 190, 158), "all"), ((194, 130, 222, 158), "all"), ((226, 128, 254, 158), "all")]),
    ("village_tank", "Tanque de tábuas", [((193, 82, 224, 126), 16), ((225, 82, 256, 126), 16)]),
    ("village_trough", "Cocho", [((128, 112, 160, 128), "all"), ((160, 112, 192, 128), "all")]),
    ("village_crate", "Caixote", [((128, 80, 144, 96), None), ((144, 80, 160, 96), None), ((160, 80, 176, 96), None), ((129, 97, 143, 111), None), ((161, 97, 175, 111), None), ((96, 104, 128, 128), 12), ((96, 136, 128, 160), 12)]),
    ("village_bench", "Banco da vila", [((65, 97, 95, 111), None), ((65, 113, 95, 127), None), ((32, 96, 64, 128), 12), ((1, 97, 15, 127), None), ((17, 97, 31, 127), None)]),
    ("village_table", "Mesa da vila", [((16, 64, 32, 80), None), ((48, 64, 64, 80), None), ((80, 64, 96, 80), None), ((114, 80, 126, 96), None)]),
    ("village_chair", "Cadeira", [((16, 48, 32, 64), None), ((48, 48, 64, 64), None), ((17, 81, 31, 95), None), ((49, 81, 63, 95), None), ((1, 64, 14, 80), None), ((34, 64, 47, 80), None), ((67, 66, 77, 78), None)]),
    ("village_signpost", "Placa de direção", [((113, 55, 127, 79), None), ((129, 55, 143, 79), None), ((145, 56, 159, 79), None), ((161, 56, 175, 79), None)]),
    ("village_board", "Placa de madeira", [((65, 129, 79, 144), None), ((81, 129, 95, 144), None), ((64, 144, 80, 160), None), ((80, 144, 96, 160), None), ((66, 162, 79, 175), None), ((81, 162, 94, 175), None)]),
    ("village_shop_sign", "Placa de loja", [(SIGN_ARM, None)] + [(("icon", i), None) for i in range(8)] + [((160, 320, 192, 352), None)]),
    ("village_lantern", "Lanterna pendurada", [((196, 416, 219, 448), None), ((196, 384, 219, 416), None)]),
    ("village_ladder", "Escada de mão", [((96, 161, 112, 176), None), ((96, 177, 112, 207), None), ((96, 210, 112, 255), None)]),
    ("village_firewood", "Lenha", [((66, 176, 79, 208), None), ((81, 176, 94, 192), None), ("log_pile", 14), ((145, 465, 158, 511), None)]),
    ("village_wheat", "Trigo", [((178, 477, 222, 495), "all"), ((161, 465, 176, 512), None), ((244, 498, 251, 510), None)]),
    ("village_garden_bed", "Canteiro de terra", [((178, 497, 222, 511), None), ((224, 481, 240, 495), None), ((224, 497, 240, 511), None)]),
    ("village_flower", "Flor da vila", [((212, 452, 219, 459), None), ((228, 449, 235, 459), None), ((244, 449, 251, 459), None), ((228, 465, 235, 475), None), ((244, 465, 251, 475), None)]),
    ("village_refuge_sign", "Placa do Refúgio", [(("icon", CROSS, color), None) for color in CROSS_COLORS]),
    ("village_store_sign", "Placa da Loja", [(SIGN_ARM, None)]),
]
FIRST_ID = 112


def trim(image):
    box = image.getbbox()
    return image.crop(box) if box else image


def is_water(pixel):
    r, g, b, a = pixel
    return a and b > r + 60


def statue_fountain(sheet):
    pool = sheet.crop((0, 400, 64, 464))
    statue = sheet.crop(STATUE)
    px = statue.load()
    for y in range(statue.height):
        for x in range(statue.width):
            if is_water(px[x, y]):
                px[x, y] = (0, 0, 0, 0)
    statue = trim(statue)
    pool.alpha_composite(statue, (32 - statue.width // 2, 34 - statue.height + 8))
    return pool


def log_pile(sheet):
    area = sheet.crop((64, 208, 96, 256))
    px = area.load()
    seed = next((x, area.height - 1) for x in range(area.width) if px[x, area.height - 1][3])
    seen, queue = {seed}, [seed]
    while queue:
        x, y = queue.pop()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if (nx, ny) not in seen and 0 <= nx < area.width and 0 <= ny < area.height and px[nx, ny][3]:
                seen.add((nx, ny))
                queue.append((nx, ny))
    out = Image.new("RGBA", area.size)
    for x, y in seen:
        out.putpixel((x, y), px[x, y])
    return out


def shop_sign(sheet, index, paint=None):
    arm = sheet.crop(SIGN_ARM)
    x, y = ICONS[index]
    icon = sheet.crop((x, y, x + ICON_SIZE[0], y + ICON_SIZE[1]))
    if paint:
        px = icon.load()
        x0, y0, x1, y1 = CROSS_BOX
        for py in range(y0, y1):
            for px_x in range(x0, x1):
                if sum(px[px_x, py][:3]) // 3 // 26 == 4:
                    px[px_x, py] = paint
    arm.alpha_composite(icon, ICON_AT)
    return arm


def art_of(sheet, source):
    if source == "statue_fountain":
        return trim(statue_fountain(sheet))
    if source == "log_pile":
        return trim(log_pile(sheet))
    if isinstance(source, tuple) and source[0] == "icon":
        return trim(shop_sign(sheet, source[1], source[2] if len(source) > 2 else None))
    return trim(sheet.crop(source))


def block_of(art, depth):
    """A caixa da base, a partir do pé: (x0, y0, x1, y1), com y para cima negativo."""
    foot = art.width // 2
    height = art.height - 2 if depth == "all" else depth
    return (2 - foot, -2, art.width - 3 - foot, -height)


def conference(sheet, path):
    cells = [(slug, index, art_of(sheet, source)) for slug, _, variants in OBJECTS for index, (source, _) in enumerate(variants, start=1)]
    per_row, cell = 10, 72
    rows = (len(cells) + per_row - 1) // per_row
    out = Image.new("RGBA", (per_row * cell, rows * cell), (80, 120, 70, 255))
    draw = ImageDraw.Draw(out)
    for n, (slug, index, art) in enumerate(cells):
        x, y = (n % per_row) * cell, (n // per_row) * cell
        out.alpha_composite(art, (x + (cell - art.width) // 2, y + cell - 12 - art.height))
        draw.text((x + 2, y + cell - 11), "%s %d" % (slug[8:16], index), fill=(255, 255, 255, 255))
    out.resize((out.width * 2, out.height * 2), Image.NEAREST).save(path)


def main():
    args = sys.argv[1:]
    if len(args) not in (1, 3) or (len(args) == 3 and args[1] != "--sheet"):
        sys.exit(__doc__)
    sheet = Image.open(args[0]).convert("RGBA")
    if len(args) == 3:
        conference(sheet, args[2])
        return
    for offset, (slug, name, variants) in enumerate(OBJECTS):
        folder = os.path.join(HERE, slug)
        os.makedirs(folder, exist_ok=True)
        for index, (source, depth) in enumerate(variants, start=1):
            art = art_of(sheet, source)
            art.save(os.path.join(folder, "%d.png" % index))
            line = "%d %s v%d %dx%d" % (FIRST_ID + offset, slug, index, art.width, art.height)
            if depth is not None:
                line += " bloqueio %s" % (block_of(art, depth),)
            print(line)


main()
