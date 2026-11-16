"""Gera os 4 ícones provisórios das partes do dia (.specs/day-night/02-day-light.md).

Uso: python -I make_day_phase_icons.py   (precisa do Pillow; roda de dentro de assets/ui/day_phases)

16×16, com o contorno escuro do tema: morning.png (sol nascendo no horizonte),
afternoon.png (sol alto), dusk.png (sol se pondo, laranja) e night.png (lua crescente).
"""

import math
import os

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SIZE = 16
OUTLINE = (10, 26, 43, 255)
SUN = [(242, 179, 61, 255), (255, 214, 102, 255), (255, 240, 180, 255)]
DUSK = [(214, 96, 48, 255), (242, 140, 70, 255), (255, 190, 120, 255)]
MOON = [(150, 170, 210, 255), (205, 220, 245, 255), (245, 250, 255, 255)]
HORIZON = [(14, 95, 175, 255), (13, 164, 246, 255)]
STAR = (255, 255, 255, 255)


def blank() -> Image.Image:
    return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))


def disc(img: Image.Image, cx: float, cy: float, r: float, shades: list, keep=lambda x, y: True) -> None:
    for y in range(SIZE):
        for x in range(SIZE):
            if not keep(x, y):
                continue
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if d <= r:
                light = (x + 0.5 - cx) * -0.6 + (y + 0.5 - cy) * -0.8
                index = 2 if light > r * 0.45 else (1 if light > -r * 0.3 else 0)
                img.putpixel((x, y), shades[index])


def rays(img: Image.Image, cx: float, cy: float, r: float, color: tuple, keep=lambda x, y: True) -> None:
    for k in range(8):
        a = k * math.pi / 4
        for dist in (r + 2, r + 3):
            x = int(round(cx - 0.5 + math.cos(a) * dist))
            y = int(round(cy - 0.5 + math.sin(a) * dist))
            if 0 <= x < SIZE and 0 <= y < SIZE and keep(x, y):
                img.putpixel((x, y), color)


def outline(img: Image.Image) -> None:
    src = img.copy()
    for y in range(SIZE):
        for x in range(SIZE):
            if src.getpixel((x, y))[3]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < SIZE and 0 <= ny < SIZE and src.getpixel((nx, ny))[3] and src.getpixel((nx, ny)) != OUTLINE:
                    img.putpixel((x, y), OUTLINE)
                    break


def horizon(img: Image.Image, top: int) -> None:
    for y in range(top, SIZE - 1):
        for x in range(1, SIZE - 1):
            img.putpixel((x, y), HORIZON[0] if y > top else HORIZON[1])


def morning() -> Image.Image:
    img = blank()
    above = lambda x, y: y < 10
    rays(img, 8, 10, 4, SUN[1], above)
    disc(img, 8, 10, 4, SUN, above)
    horizon(img, 10)
    outline(img)
    return img


def afternoon() -> Image.Image:
    img = blank()
    rays(img, 8, 8, 4, SUN[1])
    disc(img, 8, 8, 4, SUN)
    outline(img)
    return img


def dusk() -> Image.Image:
    img = blank()
    above = lambda x, y: y < 12
    disc(img, 8, 12, 5, DUSK, above)
    horizon(img, 12)
    outline(img)
    return img


def night() -> Image.Image:
    img = blank()
    cut = lambda x, y: math.hypot(x + 0.5 - 11, y + 0.5 - 5.5) > 4.2
    disc(img, 8, 8, 5.5, MOON, cut)
    for x, y in ((12, 11), (3, 2)):
        img.putpixel((x, y), STAR)
    outline(img)
    return img


if __name__ == "__main__":
    for name, make in (("morning", morning), ("afternoon", afternoon), ("dusk", dusk), ("night", night)):
        make().save(os.path.join(HERE, f"{name}.png"))
        print(f"{name}.png")
