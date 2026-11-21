"""O Altar-portal (portal-altar/01): portal_altar/1.png, com o Veilmoth no pedestal, e 2.png, vazio.

Uso, de dentro de client/assets/props: python -I make_portal_altar.py

Também grava 1_frames.png e 2_frames.png, os 16 quadros da animação lado a lado, que o mapa
troca no shader como a fumaça das casas (HexMapView.PROP_FRAMES); 1.png e 2.png são o quadro 0.

A pedra é a da Casa grande (big_house/1.png): cada bloco tem o seu tom, a borda de cima e a da
esquerda mais claras, a de baixo e a da direita mais escuras, e a junta escura entre eles.
"""
import math
import random
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
W, H = 62, 74
CX = W // 2
TOP_Y = H - 13
SHADOW = (0, 0, 0, 46)
# os quadros da animação, lado a lado em <variante>_frames.png, a FPS por segundo no mapa
FRAMES = 16
FPS = 10


def hexc(value):
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


# do claro ao escuro; os 7 do meio são os da pedra da Casa grande
STONE = [hexc(c) for c in ("a2b0ba", "8a9aa6", "768996", "6c7a86", "646e79", "565a65", "4f525d", "464752")]
MORTAR = hexc("393a42")
STONE_LINE = hexc("28282e")
ARCANE = [hexc(c) for c in ("d4ccff", "a99bff", "6c5ce7", "3b2c92")]
CYAN = hexc("7fe8ff")
WHITE = hexc("ffffff")
CREAM = [hexc(c) for c in ("fffaf0", "f4ecd8", "d8ccb0")]
MOSS = [hexc(c) for c in ("86d266", "3f9c48", "2a7038")]
MOSS_LINE = hexc("1d4a28")
EYE = hexc("22263a")

MOTH = [
    "......aa.....aa......",
    "........a...a........",
    "..1111...a.a...1111..",
    ".122221..hhh..122221.",
    "12223321heheh12332221",
    "1223cc32ghhhg23cc3221",
    "123ckwc3fffff3cwkc321",
    "123ckkc3fgfgf3ckkc321",
    "1223cc33gfffg33cc3221",
    ".23333344fff44333332.",
    "..r44444.fgf.44444r..",
    "...r2233.fff.3322r...",
    "...23cc3..g..3cc32...",
    "...r2333.....3332r...",
    "....r334.....433r....",
    ".....rr4.....4rr.....",
]
MOTH_COLORS = {
    "a": ARCANE[0], "1": ARCANE[0], "2": ARCANE[1], "3": ARCANE[2], "4": ARCANE[3], "c": CYAN, "k": EYE,
    "h": CREAM[0], "f": CREAM[1], "g": CREAM[2], "e": EYE, "r": CREAM[1], "w": WHITE,
}


class Canvas:
    def __init__(self):
        self.px = {}
        self.kind = {}

    def put(self, x, y, color, kind="stone"):
        if 0 <= x < W and 0 <= y < H:
            self.px[(x, y)] = color
            self.kind[(x, y)] = kind

    def has(self, x, y):
        return (x, y) in self.px


def ellipse(x, y, cx, cy, rx, ry):
    return ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2


def shade_blocks(canvas, blocks, rnd, bias=lambda x, y: 0, kind="stone"):
    """Cada bloco é um conjunto de pixels; o que sobra entre eles vira junta."""
    for cells in blocks:
        if not cells:
            continue
        tone = rnd.choice((3, 3, 4, 4, 5))
        for x, y in cells:
            t = tone + bias(x, y)
            if (x, y - 1) not in cells or (x - 1, y) not in cells:
                t -= 1
            if (x, y + 1) not in cells or (x + 1, y) not in cells:
                t += 1
            canvas.put(x, y, STONE[max(0, min(7, t))], kind)
        if len(cells) > 14 and rnd.random() < 0.35:
            x, y = rnd.choice(sorted(cells))
            if (x + 1, y + 1) in cells:
                canvas.put(x, y, STONE[7])
                canvas.put(x + 1, y + 1, STONE[6])


def right_bias(x, _y):
    return 1 if x > CX + 12 else 0


def draw_dais(canvas, rnd, lit, frame):
    # a lateral: blocos de 6 px, desencontrados entre as duas fiadas
    blocks = {}
    mortar = []
    for y in range(TOP_Y - 3, H - 1):
        for x in range(1, W - 1):
            side = ellipse(x, y - 5, CX - 0.5, TOP_Y, 28.5, 7)
            top = ellipse(x, y, CX - 0.5, TOP_Y, 28.5, 7)
            if side > 1 or top <= 1:
                continue
            row = 0 if y - TOP_Y - 7 * math.sqrt(max(0, 1 - ((x - CX + 0.5) / 28.5) ** 2)) < 3 else 1
            shift = 3 if row else 0
            if (x + shift) % 7 == 0:
                mortar.append((x, y))
                continue
            blocks.setdefault((row, (x + shift) // 7), set()).add((x, y))
    for key, cells in blocks.items():
        bottom = max(y for _, y in cells)
        for x, y in list(cells):
            if key[0] == 0 and (x, y + 1) not in cells and y < bottom and (x, y + 1) in sum(
                    (list(c) for k, c in blocks.items() if k[0] == 1), []):
                cells.discard((x, y))
                mortar.append((x, y))
    shade_blocks(canvas, list(blocks.values()), rnd, lambda x, y: 1 + right_bias(x, y))
    for x, y in mortar:
        canvas.put(x, y, MORTAR)

    # a face de cima: lajes em anel, com o anel arcano gravado
    for y in range(TOP_Y - 7, TOP_Y + 8):
        for x in range(1, W - 1):
            d = ellipse(x, y, CX - 0.5, TOP_Y, 28.5, 7)
            if d > 1:
                continue
            ang = math.atan2((y - TOP_Y) / 7, (x - CX + 0.5) / 28.5)
            slab = int((ang + math.pi) / (2 * math.pi) * 14)
            edge = abs(((ang + math.pi) / (2 * math.pi) * 14) - round((ang + math.pi) / (2 * math.pi) * 14)) < 0.09
            if d > 0.93:
                tone = 0 if y < TOP_Y or x < CX - 14 else 1
            elif 0.55 < d < 0.62:
                canvas.put(x, y, MORTAR)
                continue
            elif d >= 0.62 and edge:
                canvas.put(x, y, STONE[4])
                continue
            else:
                tone = (1 if d < 0.55 else 1 + (slab % 3 == 0)) + (1 if x > CX + 10 else 0)
            canvas.put(x, y, STONE[tone])
    ring_on = ARCANE[1] if lit else ARCANE[2]
    for y in range(TOP_Y - 5, TOP_Y + 6):
        for x in range(4, W - 4):
            ring = ellipse(x, y, CX - 0.5, TOP_Y, 19, 4.6)
            if 0.78 <= ring <= 1.0:
                canvas.put(x, y, ring_on if (x + y + frame // 2) % 8 else CYAN if lit else ARCANE[3], "arcane")
            elif 0.4 <= ring < 0.5 and (x * 3 + y) % 7 == 0:
                canvas.put(x, y, ARCANE[2] if not lit else ARCANE[1], "arcane")
    # o degrau da frente
    for y in range(H - 6, H - 1):
        for x in range(CX - 9, CX + 8):
            if x in (CX - 9, CX + 7) and y == H - 6:
                continue
            if (x - CX) % 6 == 2 and y > H - 6:
                canvas.put(x, y, MORTAR)
                continue
            tone = 0 if y == H - 6 else 2 if y == H - 5 else 4 if y < H - 2 else 6
            if x >= CX + 5 and y > H - 6:
                tone += 1
            canvas.put(x, y, STONE[tone])


def draw_pillar(canvas, rnd, x0, mirror):
    width = 7
    top = 17
    foot = TOP_Y + 1
    # o plinto e o capitel, um pixel mais largos de cada lado
    blocks = []
    y = top + 4
    courses = [6, 5, 7, 5, 6, 6, 5]
    for h in courses:
        if y >= foot - 4:
            break
        split = rnd.choice((None, None, 3, 4))
        rows = range(y, min(y + h - 1, foot - 4))
        if split is None:
            blocks.append({(x, yy) for x in range(x0, x0 + width) for yy in rows})
        else:
            blocks.append({(x, yy) for x in range(x0, x0 + split) for yy in rows})
            blocks.append({(x, yy) for x in range(x0 + split + 1, x0 + width) for yy in rows})
            for yy in rows:
                canvas.put(x0 + split, yy, MORTAR)
        for x in range(x0, x0 + width):
            canvas.put(x, y + h - 1, MORTAR)
        y += h
    shade_blocks(canvas, blocks, rnd, lambda x, yy: 1 if x >= x0 + width - 2 else 0)
    for yy in range(y, foot - 4):
        for x in range(x0, x0 + width):
            canvas.put(x, yy, STONE[4])
    plinth = {(x, yy) for x in range(x0 - 1, x0 + width + 1) for yy in range(foot - 4, foot + 1)}
    capital = {(x, yy) for x in range(x0 - 1, x0 + width + 1) for yy in range(top, top + 3)}
    shade_blocks(canvas, [plinth, capital], random.Random(3), lambda x, yy: 1 if x >= x0 + width - 1 else -1)
    for x in range(x0 - 1, x0 + width + 1):
        canvas.put(x, top + 3, MORTAR)
        canvas.put(x, foot - 5, MORTAR)
    # a runa gravada, um olho de mariposa em pé
    gx, gy = x0 + 2, 33
    rune = [".a.", "aca", "a.a", "aca", ".a."]
    for j, row in enumerate(rune):
        for i, ch in enumerate(row):
            if ch == "a":
                canvas.put(gx + i, gy + j, ARCANE[2], "arcane")
            elif ch == "c":
                canvas.put(gx + i, gy + j, ARCANE[1], "arcane")
    # o musgo que escorre do capitel e sobe do plinto
    side = x0 if not mirror else x0 + width - 1
    step = 1 if not mirror else -1
    for i, (dx, dy) in enumerate(((0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (0, 2), (0, 3), (step * 0, 5))):
        canvas.put(side + step * dx - (0 if not mirror else 0), top + 2 + dy, MOSS[1] if i % 3 else MOSS[0], "moss")
    for dx, dy in ((0, 0), (1, 0), (2, 0), (3, 0), (0, -1), (1, -1), (0, -2), (4, 1), (5, 1)):
        canvas.put(side + step * dx, foot - 1 + dy - 2, MOSS[1] if (dx + dy) % 2 else MOSS[2], "moss")
    canvas.put(side + step * 1, foot - 4, MOSS[0], "moss")


def draw_arch(canvas, rnd, lit, frame):
    cx, cy = CX - 0.5, 18
    outer = (26.5, 16)
    inner = (19.5, 10.5)
    count = 9
    blocks = {}
    for y in range(0, int(cy) + 1):
        for x in range(W):
            o = ellipse(x, y, cx, cy, *outer)
            i = ellipse(x, y, cx, cy, *inner)
            if o > 1 or i <= 1:
                continue
            ang = math.atan2(cy - y, x - cx)
            pos = (math.pi - ang) / math.pi * count
            k = int(pos)
            if abs(pos - round(pos)) * 20 < 1.05 and 0 < round(pos) < count:
                canvas.put(x, y, MORTAR)
                continue
            blocks.setdefault(k, set()).add((x, y))
    key = count // 2
    for k, cells in blocks.items():
        if k == key:
            continue
        tone = rnd.choice((3, 3, 4))
        for x, y in cells:
            o = ellipse(x, y, cx, cy, *outer)
            t = tone
            if (x, y - 1) not in cells and o > 0.8:
                t -= 2 if x < CX + 6 else 1
            elif (x - 1, y) not in cells:
                t -= 1
            if (x, y + 1) not in cells and o < 0.8:
                t += 2
            elif (x + 1, y) not in cells:
                t += 1
            if x > CX + 14:
                t += 1
            canvas.put(x, y, STONE[max(0, min(7, t))])
    # a pedra-chave, mais alta, com o cristal cravado
    cells = blocks.get(key, set())
    ks = {(x, y) for x in range(CX - 5, CX + 5) for y in range(1, 13)}
    for x, y in ks | cells:
        if (x, y) in ks:
            t = 3
            if y == 1 or x == CX - 5:
                t = 1
            if y == 12 or x >= CX + 3:
                t = 5
            canvas.put(x, y, STONE[t])
    for y in range(1, 13):
        canvas.put(CX - 6, y, MORTAR) if canvas.has(CX - 6, y) else None
        canvas.put(CX + 5, y, MORTAR) if canvas.has(CX + 5, y) else None
    crystal = [
        "...w...",
        "..wAB..",
        "..wAB..",
        ".wAABD.",
        ".wAABD.",
        "wAAABDD",
        ".AABBD.",
        ".ABBDD.",
        "..BDD..",
        "...D...",
    ]
    colors = {"w": ARCANE[0], "A": ARCANE[0], "B": ARCANE[1], "D": ARCANE[2]}
    if not lit:
        pulse = frame in (6, 7, 8, 9)
        colors = {"w": ARCANE[0] if pulse else ARCANE[1], "A": ARCANE[1], "B": ARCANE[1] if pulse else ARCANE[2], "D": ARCANE[3]}
    for j, row in enumerate(crystal):
        for i, ch in enumerate(row):
            if ch != ".":
                canvas.put(CX - 4 + i, j - 1 + 2, colors[ch], "arcane")
    canvas.put(CX - 2, 3, WHITE if lit else ARCANE[0], "arcane")
    canvas.put(CX - 2, 4, WHITE if lit else ARCANE[1], "arcane")
    glint = ((CX - 1, 1), (CX - 2, 2), (CX - 3, 4), (CX - 3, 5), (CX - 2, 6), (CX - 1, 7), (CX, 8))
    if lit and frame < len(glint):
        canvas.put(*glint[frame], WHITE, "arcane")
    # o musgo pendurado no arco
    for x, y in ((CX - 16, 9), (CX - 15, 9), (CX - 15, 10), (CX - 17, 9), (CX - 16, 10), (CX - 16, 11),
                 (CX + 12, 7), (CX + 13, 7), (CX + 13, 8)):
        if canvas.has(x, y) or canvas.has(x, y - 1):
            canvas.put(x, y, MOSS[1] if (x + y) % 2 else MOSS[0], "moss")


def draw_pedestal(canvas, rnd, lit, frame):
    bowl_y = TOP_Y - 18
    # o fuste, com duas fiadas
    for y in range(bowl_y + 3, TOP_Y + 1):
        for x in range(CX - 3, CX + 3):
            t = 2 if x == CX - 3 else 5 if x >= CX + 1 else 3
            if y in (bowl_y + 9, bowl_y + 14):
                t = 7
            canvas.put(x, y, STONE[t])
    for x in range(CX - 5, CX + 5):
        for y in (TOP_Y - 1, TOP_Y, TOP_Y + 1):
            t = 1 if y == TOP_Y - 1 else 3 if y == TOP_Y else 5
            if x >= CX + 3:
                t += 1
            canvas.put(x, y, STONE[t])
    # a bacia vista um pouco de cima
    for y in range(bowl_y - 3, bowl_y + 4):
        for x in range(CX - 8, CX + 8):
            d = ellipse(x, y, CX - 0.5, bowl_y, 7.5, 2.6)
            under = ellipse(x, y - 1.5, CX - 0.5, bowl_y, 6.5, 2.6)
            if d <= 1:
                if d > 0.55:
                    canvas.put(x, y, STONE[0] if y < bowl_y else STONE[2])
                else:
                    canvas.put(x, y, (CYAN if (x + y + frame // 2) % 4 == 0 else ARCANE[1]) if lit else ARCANE[3],
                               "arcane" if lit else "stone")
            elif under <= 1 and y > bowl_y:
                canvas.put(x, y, STONE[5] if x > CX + 3 else STONE[4])
    if lit:
        canvas.put(CX - 3, bowl_y - 1, WHITE, "arcane")


def arc(canvas, cx, cy, r, start, span, color, squash=1.07):
    steps = max(8, int(abs(span) * r * 1.5))
    for i in range(steps + 1):
        a = start + span * i / steps
        x, y = round(cx + r * math.cos(a)), round(cy + r * squash * math.sin(a))
        if not canvas.has(x, y) or canvas.kind.get((x, y)) == "spark":
            canvas.put(x, y, color, "spark")


SPARKS = ((CX - 13, 14, 0), (CX + 12, 18, 5), (CX - 10, 41, 10), (CX + 12, 39, 3), (CX + 4, 10, 8),
          (CX - 15, 27, 13), (CX + 15, 28, 11))


def draw_portal(canvas, lit, frame):
    cx, cy = CX - 0.5, 29
    turn = frame * 2 * math.pi / FRAMES
    if lit:
        arc(canvas, cx, cy, 14, 0, 2 * math.pi, ARCANE[2])
        arc(canvas, cx, cy, 13, math.pi * 1.05 + turn, math.pi * 0.7, CYAN)
        arc(canvas, cx, cy, 13, math.pi * 0.05 + turn, math.pi * 0.6, ARCANE[1])
        for r, start, span, color, speed in ((10, 3.6, 1.5, ARCANE[1], 1), (10, 0.5, 1.4, ARCANE[1], 1),
                                             (7, 2.2, 1.6, CYAN, 2), (7, 5.3, 1.5, ARCANE[0], 2),
                                             (4, 1.0, 1.8, ARCANE[0], 2), (4, 4.2, 1.6, CYAN, 2)):
            arc(canvas, cx, cy, r, start + turn * speed, span, color)
        for x, y, phase in SPARKS:
            step = (frame + phase) % FRAMES
            if step > 3 or canvas.has(x, y):
                continue
            if step in (1, 2):
                canvas.put(x, y, WHITE, "spark")
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if not canvas.has(x + dx, y + dy):
                        canvas.put(x + dx, y + dy, ARCANE[1], "spark")
            else:
                canvas.put(x, y, ARCANE[0], "spark")
    else:
        for k in range(12):
            arc(canvas, cx, cy, 14, k * math.pi / 6 + turn / 12, math.pi / 14, ARCANE[3])
        for half in (0, math.pi):
            arc(canvas, cx, cy, 8, 3.9 + half + turn / 2, 1.1, ARCANE[3])
            arc(canvas, cx, cy, 5, 0.8 + half - turn / 2, 0.9, ARCANE[2])


def draw_tufts(canvas):
    for x0, y0 in ((3, TOP_Y + 6), (CX + 13, H - 2), (W - 5, TOP_Y + 5), (CX - 15, H - 2)):
        for dx, dy, c in ((0, 0, 1), (1, 0, 1), (2, 0, 2), (0, -1, 0), (2, -1, 1), (1, -2, 0)):
            canvas.put(x0 + dx, y0 + dy, MOSS[c], "moss")


LIFT = (0, 0, 0, 0, 0, 0, 1, 2, 2, 1, 0, 0, 0, 0, 0, 0)
BOB = (0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0)


def draw_moth(canvas, frame):
    """As asas sobem e se fecham um pouco de vez em quando, e a mariposa flutua 1 px."""
    left = CX - 10
    top = TOP_Y - 34 + BOB[frame]
    lift = LIFT[frame]
    body = []
    for y, row in enumerate(MOTH):
        for x, ch in enumerate(row):
            if ch == ".":
                continue
            if y >= 2 and (x < 8 or x > 12):
                rise = lift if y < 10 else lift // 2
                inward = (1 if x < 8 else -1) if lift == 2 else 0
                canvas.put(left + x + inward, top + y - rise, MOTH_COLORS[ch], "moth")
            else:
                body.append((left + x, top + y, MOTH_COLORS[ch]))
    for x, y, color in body:
        canvas.put(x, y, color, "moth")


OUTLINE = {"stone": STONE_LINE, "arcane": ARCANE[3], "moss": MOSS_LINE, "moth": ARCANE[3]}


def outline(canvas, kinds):
    found = []
    for y in range(H):
        for x in range(W):
            if canvas.has(x, y):
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                k = canvas.kind.get((x + dx, y + dy))
                if k in kinds:
                    found.append((x, y, OUTLINE[k]))
                    break
    for x, y, color in found:
        canvas.put(x, y, color, "line")


def draw(with_moth: bool, frame: int = 0) -> Image.Image:
    rnd = random.Random(11)
    canvas = Canvas()
    draw_dais(canvas, rnd, with_moth, frame)
    draw_pillar(canvas, rnd, CX - 26, False)
    draw_pillar(canvas, rnd, CX + 19, True)
    draw_arch(canvas, rnd, with_moth, frame)
    draw_pedestal(canvas, rnd, with_moth, frame)
    draw_tufts(canvas)
    outline(canvas, {"stone", "arcane", "moss"})
    draw_portal(canvas, with_moth, frame)
    if with_moth:
        moth = Canvas()
        draw_moth(moth, frame)
        outline(moth, {"moth"})
        for p, color in moth.px.items():
            canvas.px[p] = color

    image = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = image.load()
    for y in range(H - 8, H):
        for x in range(W):
            if ellipse(x, y, CX - 0.5, H - 4, 30, 3.8) <= 1:
                px[x, y] = SHADOW
    for (x, y), color in canvas.px.items():
        px[x, y] = color
    return image


def main() -> None:
    folder = HERE / "portal_altar"
    folder.mkdir(exist_ok=True)
    for variant, with_moth in ((1, True), (2, False)):
        draw(with_moth).save(folder / f"{variant}.png")
        sheet = Image.new("RGBA", (W * FRAMES, H), (0, 0, 0, 0))
        for frame in range(FRAMES):
            sheet.paste(draw(with_moth, frame), (W * frame, 0))
        sheet.save(folder / f"{variant}_frames.png")
    print(folder)


if __name__ == "__main__":
    main()
