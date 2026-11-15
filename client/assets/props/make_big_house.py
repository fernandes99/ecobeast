"""Recorta a casa grande e a fumaça da chaminé do pacote Main Characters Home (home-pack/01).

Uso: python -I make_big_house.py <pasta PNG do pacote>   (precisa do Pillow; roda de dentro de assets/props)

Grava big_house/1.png, a casa de exterior.png sem mudar os pixels, e big_house/smoke.png,
os 6 quadros de 48x48 de Smoke_animation.png só com os pixels da fumaça: o que é igual à
casa embaixo sai. Imprime onde fica o canto do quadro em relação ao pé da casa, o
HexMapView.PROP_SMOKE.
"""

import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
HOUSE_SEED = (80, 60)
HOUSE_BOTTOM = 127
FRAME = 48
FRAMES = 6
SMOKE_AT = (16, -16)


def house_pixels(sheet):
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
    return seen


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    sheet = Image.open(os.path.join(sys.argv[1], "exterior.png")).convert("RGBA")
    smoke = Image.open(os.path.join(sys.argv[1], "Smoke_animation.png")).convert("RGBA")
    house = house_pixels(sheet)
    left = min(x for x, _ in house)
    top = min(y for _, y in house)
    width = max(x for x, _ in house) - left + 1
    height = max(y for _, y in house) - top + 1
    pixels = sheet.load()
    art = Image.new("RGBA", (width, height))
    for x, y in house:
        art.putpixel((x - left, y - top), pixels[x, y])
    out = os.path.join(HERE, "big_house")
    os.makedirs(out, exist_ok=True)
    art.save(os.path.join(out, "1.png"))

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
    puffs.save(os.path.join(out, "smoke.png"))
    print("casa %dx%d; quadro da fumaça em (%d, %d) do pé" % (
        width, height, SMOKE_AT[0] - left - width // 2, SMOKE_AT[1] - top - height))


main()
