"""O Altar-portal (portal-altar/01): portal_altar/1.png, com o Veilmoth no pedestal, e 2.png, vazio.

Uso, de dentro de client/assets/props: python -I make_portal_altar.py
"""
import math
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
W, H = 62, 74
CX = W // 2
SHADOW = (0, 0, 0, 46)


def hexc(value):
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


STONE = [hexc(c) for c in ("eceaf2", "bcbccc", "84849c", "56566c")]
ARCANE = [hexc(c) for c in ("d4ccff", "a99bff", "6c5ce7", "3b2c92")]
CYAN = hexc("7fe8ff")
WHITE = hexc("ffffff")
CREAM = [hexc(c) for c in ("fffaf0", "f4ecd8")]
MOSS = [hexc(c) for c in ("3f9c48", "2a7038")]
EYE = hexc("22263a")
ARCANE_SET = set(ARCANE) | {CYAN, WHITE} | set(CREAM) | {EYE}

MOTH = [
    "..a.....",
    "...a....",
    ".VV.a...",
    "VVVV.aHH",
    "VcCcVVeH",
    "VCdCVVHH",
    "VcCcVVFF",
    ".VVVVVFF",
    "..vvv.Kb",
    ".vcv...b",
    ".vt.....",
]
MOTH_COLORS = {
    "a": ARCANE[0], "V": ARCANE[2], "v": ARCANE[3], "c": CREAM[0], "C": CYAN, "d": EYE,
    "H": ARCANE[0], "e": EYE, "F": CREAM[1], "K": ARCANE[3], "b": ARCANE[2], "t": CYAN,
}


def ellipse(x, y, cx, cy, rx, ry):
    return ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2


def outline(px, color_of):
    found = []
    for y in range(H):
        for x in range(W):
            if px[x, y][3] == 255:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < W and 0 <= ny < H and px[nx, ny][3] == 255:
                    found.append((x, y, color_of(px[nx, ny])))
                    break
    for x, y, color in found:
        px[x, y] = color


def stone_outline(color):
    return ARCANE[3] if color in ARCANE_SET else STONE[3]


def draw(with_moth: bool) -> Image.Image:
    image = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = image.load()
    light, base, dark, line = STONE

    for y in range(H - 8, H):
        for x in range(W):
            if ellipse(x, y, CX - 0.5, H - 4.5, 30, 3.6) <= 1:
                px[x, y] = SHADOW

    # a base redonda: a face de cima e a lateral
    top_y = H - 13
    for y in range(top_y - 9, H - 1):
        for x in range(1, W - 1):
            top = ellipse(x, y, CX - 0.5, top_y, 28, 7)
            side = ellipse(x, y - 4, CX - 0.5, top_y, 28, 7)
            if top <= 1:
                px[x, y] = light if top > 0.82 and (y < top_y or x < CX - 18) else base
            elif side <= 1 and y > top_y - 1:
                joint = (x - 2) % 6 == 0 and y < H - 3
                px[x, y] = line if y >= H - 3 else dark if joint or x > W - 5 else base if y == top_y + 1 else dark
    for y in range(top_y - 6, top_y + 7):
        for x in range(4, W - 4):
            ring = ellipse(x, y, CX - 0.5, top_y, 19, 4.6)
            if 0.74 <= ring <= 1.0:
                px[x, y] = ARCANE[2]
            elif abs(ring - 0.3) < 0.09 and (x + y) % 3 == 0:
                px[x, y] = ARCANE[1]
    # o degrau da frente
    for y in range(H - 6, H - 1):
        for x in range(CX - 8, CX + 8):
            px[x, y] = light if y == H - 6 else base if y < H - 3 else dark
            if x >= CX + 6 and y > H - 6:
                px[x, y] = dark

    def pillar(x0):
        for y in range(14, top_y + 1):
            for x in range(x0, x0 + 6):
                px[x, y] = light if x == x0 else dark if x >= x0 + 4 else base
            if (y - 14) % 9 == 8:
                for x in range(x0, x0 + 6):
                    px[x, y] = dark
        for x in range(x0 - 1, x0 + 7):
            px[x, 13] = light
            px[x, top_y] = px[x, top_y + 1] = dark
        for x, y in ((x0, 27), (x0 + 1, 28), (x0, 29), (x0 + 4, 41), (x0 + 5, 42), (x0, 50)):
            px[x, y] = MOSS[0] if (x + y) % 2 else MOSS[1]
        px[x0 + 2, 34] = px[x0 + 3, 34] = ARCANE[1]
        px[x0 + 2, 35] = px[x0 + 3, 35] = ARCANE[2]

    pillar(CX - 25)
    pillar(CX + 19)
    # o arco
    for y in range(0, 16):
        for x in range(W):
            d = ellipse(x, y, CX - 0.5, 15, 25, 13)
            if 0.6 <= d <= 1.0:
                px[x, y] = light if d > 0.88 and x < CX + 10 else dark if d < 0.7 or x > CX + 16 else base
    # a pedra-chave de cristal
    for y in range(0, 11):
        half = 3 - abs(y - 5) * 3 // 5
        for x in range(CX - half - 1, CX + half):
            px[x, y] = ARCANE[0] if x < CX - 1 else ARCANE[1] if x == CX - 1 else ARCANE[2]
    px[CX - 2, 3] = WHITE
    # o pedestal com a bacia
    for y in range(top_y - 14, top_y + 1):
        for x in range(CX - 4, CX + 3):
            px[x, y] = light if x == CX - 4 else dark if x >= CX + 1 else base
    for x in range(CX - 6, CX + 5):
        px[x, top_y - 16] = light
        px[x, top_y - 15] = dark if x >= CX + 3 else base
    if with_moth:
        for x in range(CX - 4, CX + 3):
            px[x, top_y - 17] = CYAN if x % 2 else ARCANE[1]

    outline(px, stone_outline)

    # os fiapos do portal, soltos no vão do arco, sem contorno
    for i in range(0, 70, 2):
        a = i * 0.47
        r = 2 + i * 0.22
        x, y = round(CX - 0.5 + r * math.cos(a)), round(30 + r * 0.95 * math.sin(a))
        if CX - 17 < x < CX + 16 and 12 < y < top_y - 9 and px[x, y][3] == 0:
            if with_moth:
                px[x, y] = CYAN if i % 4 == 0 else ARCANE[1]
            elif i % 4 == 0:
                px[x, y] = ARCANE[2]

    if with_moth:
        moth = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        mp = moth.load()
        left = CX - 8
        top = top_y - 31
        for y, row in enumerate(MOTH):
            for x, ch in enumerate(row):
                if ch != ".":
                    mp[left + x, top + y] = MOTH_COLORS[ch]
                    mp[left + 14 - x, top + y] = MOTH_COLORS[ch]
        found = []
        for y in range(H):
            for x in range(W):
                if mp[x, y][3]:
                    continue
                if any(0 <= x + dx < W and 0 <= y + dy < H and mp[x + dx, y + dy][3] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    found.append((x, y))
        for p in found:
            mp[p] = ARCANE[3]
        image.alpha_composite(moth)
    return image


def main() -> None:
    folder = HERE / "portal_altar"
    folder.mkdir(exist_ok=True)
    draw(True).save(folder / "1.png")
    draw(False).save(folder / "2.png")
    print(folder)


if __name__ == "__main__":
    main()
