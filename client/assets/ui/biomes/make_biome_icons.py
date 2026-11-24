"""Desenha um ícone de 16×16 para cada bioma (.specs/explore-hud/04-pixel-frames.md, RF-05).

Pixel a pixel, com a luz de cima à esquerda e o contorno escuro do tema. O nome do arquivo é o
`slug` do bioma no catálogo (`biomes`).

Rode desta pasta: python -I make_biome_icons.py   (precisa do Pillow)
"""

import math
from pathlib import Path

from PIL import Image

HERE = Path(__file__).parent
SIZE = 16
INK = (10, 26, 43, 255)


def rgb(hex_color):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


class Icon:
    def __init__(self):
        self.image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

    def px(self, x, y, color):
        if 0 <= x < SIZE and 0 <= y < SIZE:
            self.image.putpixel((x, y), rgb(color) if isinstance(color, str) else color)

    def rows(self, x0, y0, rows, colors):
        for j, row in enumerate(rows):
            for i, key in enumerate(row):
                if key in colors:
                    self.px(x0 + i, y0 + j, colors[key])

    def ellipse(self, cx, cy, rx, ry, light, mid, dark, keep=lambda x, y: True):
        for y in range(SIZE):
            for x in range(SIZE):
                dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
                if dx * dx + dy * dy > 1 or not keep(x, y):
                    continue
                shade = dx * 0.6 + dy * 0.8
                self.px(x, y, light if shade < -0.35 else (dark if shade > 0.35 else mid))

    def save(self, slug):
        source = self.image.copy()
        for y in range(SIZE):
            for x in range(SIZE):
                if source.getpixel((x, y))[3] > 0:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < SIZE and 0 <= ny < SIZE and source.getpixel((nx, ny))[3] > 0:
                        self.image.putpixel((x, y), INK)
                        break
        self.image.save(HERE / f"{slug}.png")


def pine(icon, x0, y0, tall):
    """Um pinheiro de três andares, a ponta em (x0, y0)."""
    light, mid, dark, trunk = "#7cc46a", "#3f8f4c", "#2a6338", "#7a4a26"
    for level in range(tall):
        width = level // 2 + 1
        for dx in range(-width, width + 1):
            color = light if dx < 0 else (dark if dx > 0 else mid)
            icon.px(x0 + dx, y0 + level, color)
    icon.px(x0, y0 + tall, trunk)
    icon.px(x0, y0 + tall + 1, trunk)


def waves(icon, rows, light, mid):
    for y in rows:
        for x in range(1, 15):
            phase = (x + y) % 6
            if phase in (0, 1):
                icon.px(x, y - 1, light)
            elif phase in (2, 3, 4):
                icon.px(x, y, mid)


def temperate():
    icon = Icon()
    icon.ellipse(8, 15, 8, 6, "#8fd06a", "#5fae4e", "#3f8a3c", keep=lambda x, y: y < 15)
    for x, h in ((3, 2), (6, 3), (11, 2), (13, 3)):
        for k in range(h):
            icon.px(x, 9 - k, "#6cbb55")
    icon.rows(7, 3, [".a.", "aba", ".a."], {"a": "#f5d24a", "b": "#e86a5a"})
    icon.px(8, 6, "#3f8a3c")
    icon.px(8, 7, "#3f8a3c")
    icon.save("temperate")


def boreal():
    icon = Icon()
    pine(icon, 5, 2, 9)
    pine(icon, 11, 4, 8)
    icon.save("boreal")


def stone():
    icon = Icon()
    icon.ellipse(6, 10, 5, 4, "#c4ccd6", "#8e98a6", "#5d6674")
    icon.ellipse(11, 12, 4, 3, "#b3bcc8", "#7f8998", "#555e6c")
    icon.ellipse(9, 6, 3, 2.5, "#d4dae2", "#9aa4b2", "#6a7380")
    icon.save("stone")


def hill():
    icon = Icon()
    icon.ellipse(6, 14, 7, 8, "#a6d873", "#72b555", "#4b8a3e", keep=lambda x, y: y < 15)
    icon.ellipse(12, 15, 5, 5, "#94cc66", "#63a54c", "#437d38", keep=lambda x, y: y < 15)
    icon.save("hill")


def mountain():
    icon = Icon()
    for y in range(2, 15):
        half = (y - 2) * 7 // 12
        for x in range(8 - half, 8 + half + 1):
            if y < 6:
                color = "#ffffff" if x <= 8 else "#d6e2ee"
            else:
                color = "#9aa6b6" if x < 8 else ("#7d8899" if x == 8 else "#5c6676")
            icon.px(x, y, color)
    icon.save("mountain")


def pool(icon, light, mid, dark, crest):
    icon.ellipse(8, 9.5, 7.5, 6, light, mid, dark)
    for y, x0 in ((7, 3), (10, 6), (13, 4)):
        for x in range(x0, x0 + 6):
            if (x - x0) % 6 < 3 and icon.image.getpixel((x, y))[3] > 0:
                icon.px(x, y, crest)


def wshallow():
    icon = Icon()
    pool(icon, "#8fdcff", "#5cc0f0", "#3a9ed6", "#e4f7ff")
    icon.save("wshallow")


def wdeep():
    icon = Icon()
    pool(icon, "#3b7fd6", "#245fb0", "#173f80", "#8cc4ff")
    icon.save("wdeep")


def desert():
    icon = Icon()
    icon.ellipse(6, 16, 9, 6, "#f8df9a", "#e8c070", "#c99a4c", keep=lambda x, y: y < 15)
    icon.rows(9, 3, [
        "..a..",
        "a.a..",
        "a.a.a",
        "aaa.a",
        "..aaa",
        "..a..",
        "..a..",
        "..a..",
    ], {"a": "#4f9a50"})
    icon.save("desert")


def snow():
    icon = Icon()
    for k in range(-5, 6):
        icon.px(8 + k, 8, "#ffffff")
        icon.px(8, 8 + k, "#ffffff")
        if abs(k) <= 3:
            icon.px(8 + k, 8 + k, "#d6ecff")
            icon.px(8 + k, 8 - k, "#d6ecff")
    for sx, sy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        icon.px(8 + sx * 4 + sy, 8 + sy * 4 + sx, "#ffffff")
        icon.px(8 + sx * 4 - sy, 8 + sy * 4 - sx, "#ffffff")
    icon.save("snow")


def beach():
    icon = Icon()
    icon.ellipse(8, 17, 9, 5, "#fbe7b0", "#efd08a", "#d4b066", keep=lambda x, y: y < 15)
    for y in range(6, 14):
        icon.px(7 + (y - 6) // 4, y, "#8a5a30")
    icon.rows(2, 2, [
        "..aaa.bbb..",
        ".a...ab..b.",
        "a....a....b",
        ".....a.....",
    ], {"a": "#5fae4e", "b": "#3f8a3c"})
    icon.save("beach")


def glacier():
    icon = Icon()
    for y in range(3, 15):
        half = min(y - 3, 6)
        for x in range(8 - half, 8 + half + 1):
            if y > 11:
                color = "#7cc0e8"
            elif x < 8:
                color = "#e8f8ff"
            elif x == 8:
                color = "#b6e2f6"
            else:
                color = "#8fcbe8"
            icon.px(x, y, color)
    icon.save("glacier")


def volcano():
    icon = Icon()
    for y in range(6, 15):
        half = 2 + (y - 6) * 5 // 8
        for x in range(8 - half, 8 + half + 1):
            icon.px(x, y, "#6e5548" if x < 8 else "#4a3a34")
    for x in range(6, 11):
        icon.px(x, 6, "#ff6a2a")
    icon.px(7, 7, "#ffb02e")
    icon.px(8, 7, "#ff6a2a")
    icon.px(9, 8, "#ff6a2a")
    icon.rows(6, 1, [".aa..", "aaaa.", ".a.aa"], {"a": "#9aa0aa"})
    icon.save("volcano")


def lava(slug, deep):
    icon = Icon()
    if deep:
        pool(icon, "#e0501e", "#a8221a", "#6e1410", "#ffb02e")
    else:
        pool(icon, "#ffb02e", "#ff6a2a", "#c83a18", "#ffe27a")
    for x, y in ((5, 5), (11, 8)):
        icon.px(x, y, "#ffe27a")
    icon.save(slug)


if __name__ == "__main__":
    temperate()
    boreal()
    stone()
    hill()
    mountain()
    wshallow()
    wdeep()
    desert()
    snow()
    beach()
    glacier()
    volcano()
    lava("lshallow", False)
    lava("ldeep", True)
    print("ok")
