"""Desenha as pedras gigantes da Montanha (.specs/giant-rocks/01-rock-props.md).

Uso: python -I make_giant_rocks.py [--preview saida.png]   (precisa do Pillow; roda de qualquer pasta)

Cada pedra é uma forma de blocos com facetas, contorno escuro e a luz de cima à esquerda,
gravada em <slug>/<variante>.png com o pé no meio da borda de baixo. No fim, imprime a
linha de bloqueio de cada variante, a mesma da migration e do gerador do servidor.
As pedras de gelo da Geleira (.specs/glacier/02-ice-rocks.md) usam o material gelo: facetas
lisas, sem grão, com as emendas claras e o brilho de 1 px nas arestas. Com --preview, grava
só a prévia ampliada, sem mexer nos PNGs do jogo.
"""

import math
import os
import random
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
LIGHT = (-0.55, -0.7, 0.45)
BAYER = [[0.0, 0.5], [0.75, 0.25]]
SHADOW = (12, 20, 18, 80)

# Do chão da Montanha, um pouco mais frio e com mais contraste para a pedra saltar dele.
BROWN = [(40, 33, 31), (70, 60, 56), (92, 81, 74), (113, 101, 91), (136, 123, 110), (160, 147, 131), (186, 174, 156), (212, 202, 184)]
GRANITE = [(36, 38, 44), (64, 68, 76), (86, 91, 99), (108, 114, 121), (132, 138, 144), (158, 164, 168), (186, 191, 193), (214, 218, 218)]
MOSS = [(38, 66, 40), (58, 94, 48), (84, 122, 58), (118, 150, 72)]
SNOW = [(120, 140, 172), (170, 190, 218), (210, 224, 242), (240, 246, 252)]
DRY = [(98, 96, 58), (132, 128, 74), (168, 160, 98), (200, 190, 126)]
LICHEN = [(196, 168, 74), (168, 184, 96), (222, 204, 124)]
# O contorno azul-escuro e 7 tons de azul e branco.
ICE = [(30, 54, 96), (58, 100, 150), (82, 132, 184), (110, 166, 212), (146, 198, 234), (184, 224, 246), (218, 242, 252), (248, 253, 255)]


def shade(nx, ny, levels, x, y, bias=0.0):
    nz = math.sqrt(max(0.0, 1.0 - nx * nx - ny * ny))
    length = math.sqrt(sum(k * k for k in LIGHT))
    light = (nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2]) / length
    value = min(max((light + 0.3) / 1.25 + bias, 0.0), 0.999) * levels
    return min(int(value), levels - 1), value - int(value)


def jagged(points, rng, step=5, amount=1.5):
    out = []
    for (x0, y0), (x1, y1) in zip(points, points[1:] + points[:1]):
        n = max(1, int(math.hypot(x1 - x0, y1 - y0) / step))
        for k in range(n):
            t = k / n
            j = 0 if k == 0 else amount
            out.append((x0 + (x1 - x0) * t + rng.uniform(-j, j), y0 + (y1 - y0) * t + rng.uniform(-j, j)))
    return out


class Rock:
    def __init__(self, size, palette, seed, smooth=False):
        self.smooth = smooth
        self.w, self.h = size
        self.palette = palette
        self.rng = random.Random(seed)
        self.owner = {}  # pixel -> chunk index
        self.chunks = []
        self.pixels = {}
        self.extra = {}

    def chunk(self, points, depth=0.55, stretch=(1.0, 0.35), facets=None, bias=0.0, rough=True, front=False):
        """Um bloco de pedra: os de baixo (maior y do pé) ficam na frente, menos o `front`."""
        if rough:
            points = jagged(points, self.rng)
        mask = Image.new("L", (self.w, self.h), 0)
        ImageDraw.Draw(mask).polygon(points, fill=255)
        data = mask.load()
        spots = {(x, y) for y in range(self.h) for x in range(self.w) if data[x, y]}
        foot = max(y for _, y in spots)
        self.chunks.append(dict(spots=spots, foot=foot, rank=foot + (1000 if front else 0), depth=depth, stretch=stretch, facets=facets, bias=bias))

    def render(self):
        order = sorted(range(len(self.chunks)), key=lambda i: self.chunks[i]["rank"])
        for i in order:
            for spot in self.chunks[i]["spots"]:
                self.owner[spot] = i
        tones = self.palette[1:]
        top = len(tones) - 1
        self.top_of = {}
        for i, c in enumerate(self.chunks):
            mine = [s for s, o in self.owner.items() if o == i]
            if not mine:
                continue
            cols, rows = {}, {}
            for x, y in mine:
                cols.setdefault(x, []).append(y)
                rows.setdefault(y, []).append(x)
            ys = [y for _, y in mine]
            y0, y1 = min(ys), max(ys)
            height = max(1, y1 - y0)
            n = c["facets"] or max(3, len(mine) // 70)
            seeds = self.rng.sample(sorted(mine), min(n, len(mine)))
            sx, sy = c["stretch"]
            facet = {}
            for x, y in mine:
                facet[(x, y)] = min(range(len(seeds)), key=lambda k: (x - seeds[k][0]) ** 2 * sx + (y - seeds[k][1]) ** 2 * sy)
            normals = {}
            for x, y in mine:
                left, right = min(rows[y]), max(rows[y])
                half = max(1.0, (right - left) / 2)
                nx = (x + 0.5 - (left + right + 1) / 2) / half
                dtop = y - min(cols[x])
                ny = -0.95 + 1.7 * min(1.0, dtop / (height * c["depth"]))
                normals.setdefault(facet[(x, y)], []).append((nx, ny))
            tone_of = {}
            for k, ns in normals.items():
                nx = sum(a for a, _ in ns) / len(ns) * 0.85 + self.rng.uniform(-0.15, 0.15)
                ny = sum(b for _, b in ns) / len(ns) + self.rng.uniform(-0.12, 0.12)
                nx, ny = max(-0.97, min(0.97, nx)), max(-0.97, min(0.97, ny))
                tone_of[k] = shade(nx, ny, len(tones), 0, 0, c["bias"])[0]
            for x, y in mine:
                self.pixels[(x, y)] = tones[tone_of[facet[(x, y)]]]
                self.top_of[(x, y)] = (y - min(cols[x])) / height
            # rachaduras entre facetas: linha escura e um fio de luz em cima dela
            for x, y in mine:
                f = facet[(x, y)]
                for dx, dy in ((1, 0), (0, 1)):
                    g = facet.get((x + dx, y + dy))
                    if g is not None and g != f and self.owner.get((x + dx, y + dy)) == i:
                        a, b = tone_of[f], tone_of[g]
                        if self.smooth:
                            if abs(a - b) >= 1:
                                self.pixels[(x + dx, y + dy)] = tones[min(top, max(a, b) + 1)]
                        elif abs(a - b) >= 1 or self.rng.random() < 0.5:
                            self.pixels[(x + dx, y + dy)] = tones[max(0, min(a, b) - 1)]
                            if (x, y - 1 if dy else y) in facet and tone_of[f] < top and self.rng.random() < 0.6:
                                self.pixels[(x, y)] = tones[min(top, tone_of[f] + 1)]
            # grão da pedra
            for x, y in self.rng.sample(sorted(mine), 0 if self.smooth else len(mine) // 22):
                t = tones.index(self.pixels[(x, y)])
                self.pixels[(x, y)] = tones[max(0, min(top, t + self.rng.choice([-1, 1])))]
        # contorno de fora e entre blocos
        outline = self.palette[0]
        inner = self.palette[1]
        for (x, y), i in list(self.owner.items()):
            near = [self.owner.get((x + dx, y + dy)) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
            if any(o is None for o in near):
                self.pixels[(x, y)] = outline
            elif any(o is not None and o != i and self.chunks[o]["rank"] < self.chunks[i]["rank"] for o in near):
                self.pixels[(x, y)] = inner

    def inside(self):
        return [s for s in sorted(self.owner) if self.pixels[s] not in (self.palette[0], self.palette[1])]

    def snow(self, reach=0.28):
        for (x, y) in self.inside():
            limit = reach + 0.08 * math.sin(x * 0.9) + self.rng.uniform(-0.04, 0.04)
            if self.top_of[(x, y)] < limit:
                tones = self.palette[1:]
                t = tones.index(self.pixels[(x, y)]) if self.pixels[(x, y)] in tones else 3
                level = 3 if t >= 4 else 2 if t >= 2 else 1
                if self.top_of[(x, y)] > limit - 0.05:
                    level = max(1, level - 1)
                self.pixels[(x, y)] = SNOW[level]
        for (x, y), i in self.owner.items():
            if self.pixels[(x, y)] == self.palette[0] and self.top_of.get((x, y), 1) < reach * 0.8:
                self.pixels[(x, y)] = SNOW[0]

    def moss(self, count):
        tops = [s for s in self.inside() if self.top_of[s] < 0.45 and self.palette[1:].index(self.pixels[s]) >= 3]
        for _ in range(count):
            if not tops:
                return
            cx, cy = self.rng.choice(tops)
            r = self.rng.uniform(1.5, 3.2)
            for y in range(int(cy - r), int(cy + r) + 1):
                for x in range(int(cx - r * 1.4), int(cx + r * 1.4) + 1):
                    if ((x - cx) / 1.4) ** 2 + (y - cy) ** 2 <= r * r and (x, y) in self.owner and self.pixels[(x, y)] not in (self.palette[0], self.palette[1]):
                        light = 3 if y < cy - r / 2 else 2 if y < cy + r / 3 else 1
                        if (x + y) % 2 and light > 1 and self.rng.random() < 0.3:
                            light -= 1
                        self.pixels[(x, y)] = MOSS[light]

    def lichen(self, count):
        spots = [s for s in self.inside() if self.top_of[s] < 0.7]
        for _ in range(count):
            x, y = self.rng.choice(spots)
            for dx, dy in ((0, 0), (1, 0), (0, 1)):
                if (x + dx, y + dy) in self.owner and self.pixels[(x + dx, y + dy)] not in (self.palette[0],):
                    self.pixels[(x + dx, y + dy)] = LICHEN[self.rng.randrange(3)]

    def _foot(self):
        foot = {}
        for x, y in self.owner:
            foot[x] = max(foot.get(x, -1), y)
        return foot

    def tufts(self, count, palette=DRY):
        foot = self._foot()
        xs = sorted(foot)
        for _ in range(count):
            x = self.rng.choice(xs[:len(xs) // 4] + xs[-len(xs) // 4:])
            base = foot[x] + self.rng.randint(1, 2)
            for b in range(self.rng.randint(4, 6)):
                bx = x + b - 2
                hgt = self.rng.randint(3, 6) - abs(b - 2)
                lean = -1 if b < 2 else 1 if b > 3 else 0
                for k in range(max(2, hgt)):
                    px = bx + (lean if k >= max(2, hgt) - 2 else 0)
                    self.extra[(px, base - k)] = palette[min(3, k * 4 // max(2, hgt))]

    def pebbles(self, count):
        foot = self._foot()
        xs = sorted(foot)
        bottom = max(foot.values())
        tones = self.palette
        for _ in range(count):
            side = self.rng.choice([-1, 1])
            w = self.rng.randint(5, 7)
            x = xs[0] - w - self.rng.randint(0, 3) if side < 0 else xs[-1] + self.rng.randint(1, 4)
            y = bottom - self.rng.randint(0, 3)
            for dx in range(w):
                for dy in range(-3, 1):
                    edge = dx in (0, w - 1) or dy in (-3, 0)
                    corner = dx in (0, w - 1) and dy in (-3, 0)
                    if not corner:
                        self.extra[(x + dx, y + dy)] = tones[0] if edge else tones[6] if dy == -2 and dx < w - 2 else tones[4]

    def ice(self, streaks=3):
        """O acabamento do gelo: o fundo mais azul, riscos claros por dentro e o brilho de
        1 px nas arestas de cima e da esquerda."""
        tones = self.palette[1:]
        top = len(tones) - 1
        for spot in self.inside():
            t = tones.index(self.pixels[spot]) if self.pixels[spot] in tones else 0
            if self.top_of[spot] > 0.78 and t > 0:
                self.pixels[spot] = tones[t - 1]
        inside = set(self.inside())
        for _ in range(streaks):
            x, y = self.rng.choice(sorted(inside))
            for k in range(self.rng.randint(4, 9)):
                spot = (x + (k // 3 if self.rng.random() < 0.5 else 0), y + k)
                if spot in inside:
                    t = tones.index(self.pixels[spot]) if self.pixels[spot] in tones else 0
                    self.pixels[spot] = tones[min(top, t + 2)]
        outline = self.palette[0]
        for x, y in sorted(inside):
            up, left = self.pixels.get((x, y - 1)), self.pixels.get((x - 1, y))
            if (up in (None, outline) or left in (None, outline)) and self.top_of[(x, y)] < 0.7:
                self.pixels[(x, y)] = tones[top]

    def icicles(self, index):
        """Sincelos pendurados da borda de baixo do bloco `index`, por cima do que há embaixo."""
        tones = self.palette[1:]
        columns = {}
        for (x, y), owner in self.owner.items():
            if owner == index:
                columns[x] = max(columns.get(x, -1), y + 1)
        xs = sorted(columns)
        x = xs[0] + self.rng.randint(2, 4)
        while x < xs[-1] - 2:
            width = self.rng.choice([1, 2, 2, 3])
            length = self.rng.randint(4, 12)
            base = columns.get(x, columns[xs[len(xs) // 2]])
            for k in range(length):
                w = max(1, round(width * (1 - k / length)))
                for dx in range(w):
                    color = tones[-1] if dx == 0 else (tones[2] if dx == w - 1 and w > 1 else tones[4])
                    self.pixels[(x + dx, base + k)] = color
                self.pixels[(x + w, base + k)] = self.palette[1]
            x += width + self.rng.randint(2, 5)

    def drift(self, count=3):
        """Neve soprada no pé."""
        foot = self._foot()
        xs = sorted(foot)
        for _ in range(count):
            cx = self.rng.choice(xs)
            w, h = self.rng.uniform(5, 9), self.rng.uniform(2.5, 4.5)
            base = foot[cx] + 2
            for x in range(int(cx - w), int(cx + w) + 1):
                d = (x + 0.5 - cx) / w
                if abs(d) >= 1:
                    continue
                height = round(h * math.sqrt(1 - d * d))
                for k in range(height + 1):
                    edge = k == height or abs(d) > 0.85
                    self.extra[(x, base - k)] = SNOW[0] if edge else (SNOW[3] if k > height * 0.5 and d < 0.3 else SNOW[2])

    def image(self, pad=4, bases=None):
        """A imagem com o pé no meio da borda de baixo e as linhas de bloqueio do pé:
        uma no pé inteiro, ou uma por trecho (esquerda, direita) de `bases`."""
        foot = max(y for _, y in self.owner)
        left = min(x for x, y in self.owner if y > foot - 16)
        right = max(x for x, y in self.owner if y > foot - 16)
        cx, rx, ry = (left + right) / 2, (right - left) / 2 + 4, max(3, (right - left) / 7)
        shadow = {}
        for y in range(int(foot - ry), int(foot + ry) + 1):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if ((x - cx) / rx) ** 2 + ((y - foot) / ry) ** 2 <= 1:
                    shadow[(x, y)] = SHADOW
        spots = list(self.owner) + list(self.extra) + list(shadow)
        fx = round(cx)
        half = max(max(abs(x - fx) for x, _ in spots) + pad, 1)
        x0, x1 = fx - half, fx + half - 1
        y0, y1 = min(y for _, y in spots) - 1, max(y for _, y in spots)
        img = Image.new("RGBA", (x1 - x0 + 1, y1 - y0 + 1), (0, 0, 0, 0))
        data = img.load()
        for (x, y), color in shadow.items():
            if x0 <= x <= x1:
                data[x - x0, y - y0] = color
        for (x, y), color in self.pixels.items():
            data[x - x0, y - y0] = tuple(color) + (255,)
        for (x, y), color in self.extra.items():
            if (x, y) not in self.owner and x0 <= x <= x1 and y0 <= y <= y1:
                data[x - x0, y - y0] = SHADOW if len(color) == 4 else tuple(color) + (255,)
        if bases is None:
            width = right - left
            a = round(width * 0.4)
            b = min(14, round(width * 0.16))
            cy = foot - y1 - b + 2
            return img, [-a, cy, -a // 2, cy + b, a // 2, cy + b, a, cy, a // 2, cy - b, -a // 2, cy - b]
        blocks = []
        for base_left, base_right in bases:
            mid = round((base_left + base_right) / 2) - fx
            a = round((base_right - base_left) * 0.45)
            b = max(3, min(8, round((base_right - base_left) * 0.25)))
            cy = foot - y1 - b + 2
            blocks.append([mid - a, cy, mid - a // 2, cy + b, mid + a // 2, cy + b, mid + a, cy, mid + a // 2, cy - b, mid - a // 2, cy - b])
        return img, blocks


def crag(seed, palette=BROWN, snow=False, moss=0):
    """Rochedo: um bloco alto de pico torto, dois de lado e pedras na frente."""
    r = Rock((110, 110), palette, seed)
    rng = r.rng
    peak = rng.randint(-6, 6)
    r.chunk([(30, 96), (34, 50), (46 + peak, 14), (58 + peak, 18), (70, 44), (76, 96)], depth=0.5, stretch=(1.0, 0.25))
    r.chunk([(16, 100), (18, 72), (28, 58), (40, 62), (46, 100)], depth=0.45)
    r.chunk([(62, 100), (66, 66), (80, 56), (90, 70), (92, 100)], depth=0.45)
    r.chunk([(36, 104), (40, 92), (52, 88), (60, 96), (58, 104)], depth=0.6, stretch=(1.0, 0.6))
    r.render()
    if snow:
        r.snow(0.3)
    if moss:
        r.moss(moss)
    r.lichen(4)
    r.tufts(3)
    r.pebbles(3)
    return r.image()


def pinnacles(seed, palette=BROWN, snow=False):
    """Pináculos: duas ou três agulhas de alturas diferentes."""
    r = Rock((90, 120), palette, seed)
    rng = r.rng
    r.chunk([(34, 110), (36, 40), (42, 10 + rng.randint(0, 6)), (50, 14), (54, 46), (56, 110)], depth=0.35, stretch=(1.0, 0.12), facets=7)
    r.chunk([(18, 112), (20, 60), (26, 42), (32, 48), (36, 112)], depth=0.35, stretch=(1.0, 0.12), facets=4)
    r.chunk([(52, 114), (54, 72), (62, 56), (68, 64), (72, 114)], depth=0.35, stretch=(1.0, 0.12), facets=4)
    r.chunk([(28, 116), (32, 106), (44, 102), (50, 110), (46, 116)], depth=0.6, stretch=(1.0, 0.6))
    r.render()
    if snow:
        r.snow(0.22)
    r.lichen(3)
    r.tufts(2)
    r.pebbles(2)
    return r.image()


def tilted_slab(seed, palette=BROWN, snow=False, moss=0):
    """Laje inclinada: uma placa de rocha saindo do chão, com o topo claro."""
    r = Rock((120, 80), palette, seed)
    r.chunk([(12, 66), (22, 40), (60, 20), (98, 30), (106, 64), (70, 72)], depth=0.55, stretch=(0.3, 1.0), facets=9)
    r.chunk([(80, 70), (86, 50), (100, 46), (112, 58), (110, 72)], depth=0.5)
    r.chunk([(6, 70), (10, 56), (22, 54), (28, 70)], depth=0.5)
    r.render()
    if snow:
        r.snow(0.35)
    if moss:
        r.moss(moss)
    r.lichen(3)
    r.tufts(3)
    r.pebbles(2)
    return r.image()


def boulder_pile(seed, palette=BROWN, snow=False, moss=0):
    """Matacões: blocos grandes e arredondados, um em cima do outro."""
    r = Rock((110, 100), palette, seed)
    rng = r.rng

    def round_chunk(cx, cy, rx, ry, k=9):
        pts = [(cx + math.cos(a) * rx * rng.uniform(0.9, 1.05), cy + math.sin(a) * ry * rng.uniform(0.9, 1.05)) for a in [i * math.tau / k for i in range(k)]]
        r.chunk(pts, depth=0.7, stretch=(1.0, 0.8))

    round_chunk(40, 72, 26, 20)
    round_chunk(74, 76, 22, 16)
    round_chunk(54, 44, 20, 17)
    round_chunk(30, 88, 12, 9)
    r.render()
    if snow:
        r.snow(0.3)
    if moss:
        r.moss(moss)
    r.lichen(5)
    r.tufts(4)
    r.pebbles(3)
    return r.image()


def ridge(seed, palette=BROWN, snow=False):
    """Crista: uma parede baixa e comprida de rocha serrilhada, para 2 hexágonos."""
    r = Rock((150, 90), palette, seed)
    rng = r.rng
    # o meio é mais alto, e os blocos de trás (pé mais alto) ficam atrás dos da frente
    blocks = [(8, 34, 58, 82), (26, 64, 30, 78), (54, 92, 12, 74), (84, 118, 26, 80), (110, 144, 50, 84), (36, 58, 62, 86), (96, 112, 64, 86)]
    for a, b, top, foot in blocks:
        top += rng.randint(-4, 4)
        mid = (a + b) / 2 + rng.uniform(-4, 4)
        r.chunk([(a, foot), (a + 2, top + (foot - top) * 0.45), (mid - 3, top + 2), (mid + 1, top), (b - 3, top + (foot - top) * 0.35), (b, foot)], depth=0.45, stretch=(1.0, 0.2))
    r.render()
    if snow:
        r.snow(0.3)
    r.lichen(5)
    r.tufts(4)
    r.pebbles(3)
    return r.image()


def ice_block(seed, snow=False):
    """Bloco de gelo: um bloco grande de facetas lisas, com um menor ao lado."""
    r = Rock((110, 110), ICE, seed, smooth=True)
    tilt = r.rng.randint(-4, 4)
    r.chunk([(26, 92), (24, 50), (36, 28 + tilt), (62, 22 - tilt), (78, 36), (80, 90)], depth=0.42, stretch=(1.0, 0.3), facets=6, rough=False)
    r.chunk([(66, 98), (68, 66), (80, 56), (92, 64), (92, 98)], depth=0.45, facets=3, rough=False)
    r.chunk([(32, 102), (36, 90), (50, 88), (56, 96), (52, 102)], depth=0.6, stretch=(1.0, 0.6), facets=2, rough=False)
    r.render()
    r.ice()
    if snow:
        r.snow(0.24)
    r.drift(2)
    return r.image()


def ice_spires(seed):
    """Pináculos de gelo: espetos que saem do chão em grupo, de alturas diferentes."""
    r = Rock((100, 120), ICE, seed, smooth=True)
    rng = r.rng
    for left, right, top in [(42, 58, 12), (24, 38, 44), (58, 72, 34), (72, 84, 62), (12, 24, 70)]:
        top += rng.randint(-4, 4)
        mid = (left + right) / 2 + rng.uniform(-2, 2)
        foot = 108 - (right - left) // 3 + rng.randint(-2, 2)
        r.chunk([(left, foot), (left + 2, top + (foot - top) * 0.5), (mid, top), (right - 2, top + (foot - top) * 0.4), (right, foot)], depth=0.3, stretch=(1.0, 0.1), facets=3, rough=False)
    r.chunk([(30, 114), (34, 104), (48, 100), (56, 108), (52, 114)], depth=0.6, stretch=(1.0, 0.6), facets=2, rough=False)
    r.render()
    r.ice(streaks=4)
    r.drift(2)
    return r.image()


def ice_arch(seed):
    """Arco de gelo: duas pernas e o arco por cima; só as pernas bloqueiam."""
    r = Rock((120, 100), ICE, seed, smooth=True)
    outer = [(58 + 40 * math.cos(a), 62 - 46 * math.sin(a)) for a in [math.pi * k / 14 for k in range(14, -1, -1)]]
    inner = [(58 + 24 * math.cos(a), 66 - 30 * math.sin(a)) for a in [math.pi * k / 14 for k in range(15)]]
    r.chunk(outer + inner, depth=0.5, stretch=(0.4, 1.0), facets=7, rough=False)
    r.chunk([(16, 94), (18, 56), (28, 46), (38, 52), (38, 94)], depth=0.4, stretch=(1.0, 0.3), facets=3, rough=False)
    r.chunk([(78, 94), (78, 52), (90, 44), (100, 56), (100, 94)], depth=0.4, stretch=(1.0, 0.3), facets=3, rough=False)
    r.render()
    r.ice(streaks=3)
    r.drift(2)
    return r.image(bases=[(16, 38), (78, 100)])


def trapped_rock(seed):
    """Rocha presa no gelo: uma pedra escura vista por dentro de um bloco de gelo."""
    r = Rock((110, 100), ICE, seed, smooth=True)
    r.chunk([(20, 88), (22, 46), (40, 30), (70, 28), (88, 44), (90, 88)], depth=0.4, stretch=(1.0, 0.35), facets=5, rough=False)
    r.chunk([(28, 96), (32, 84), (50, 82), (58, 90), (54, 96)], depth=0.6, stretch=(1.0, 0.6), facets=2, rough=False)
    r.render()
    rock = Rock((110, 100), GRANITE, seed + 1)
    rng = rock.rng
    rock.chunk([(50 + math.cos(a) * 20 * rng.uniform(0.85, 1.05), 60 + math.sin(a) * 16 * rng.uniform(0.85, 1.05)) for a in [k * math.tau / 9 for k in range(9)]], depth=0.7, stretch=(1.0, 0.8))
    rock.chunk([(74 + math.cos(a) * 8, 52 + math.sin(a) * 7) for a in [k * math.tau / 7 for k in range(7)]], depth=0.7, stretch=(1.0, 0.8))
    rock.render()
    for spot, color in rock.pixels.items():
        if spot in r.owner and r.pixels[spot] != ICE[0]:
            r.pixels[spot] = tuple(round(c * 0.7 + t * 0.3) for c, t in zip(color, ICE[4]))
    r.ice(streaks=4)
    r.drift(2)
    return r.image()


def icicle_block(seed):
    """Bloco com sincelos: uma laje larga por cima do bloco, com pingentes de gelo na borda."""
    r = Rock((120, 100), ICE, seed, smooth=True)
    r.chunk([(28, 94), (28, 50), (84, 50), (84, 94)], depth=0.2, stretch=(1.0, 0.2), facets=4, rough=False)
    r.chunk([(14, 48), (26, 30), (80, 24), (98, 36), (96, 54), (60, 60), (20, 56)], depth=0.7, stretch=(0.5, 1.0), facets=4, rough=False, front=True)
    r.chunk([(76, 98), (78, 74), (88, 68), (98, 76), (98, 98)], depth=0.45, facets=2, rough=False)
    r.render()
    r.ice(streaks=2)
    r.icicles(1)
    r.drift(2)
    return r.image()


def ice_shelf(seed):
    """Laje de gelo: uma placa inclinada saindo do chão, com a neve soprada no pé."""
    r = Rock((130, 80), ICE, seed, smooth=True)
    r.chunk([(12, 66), (22, 40), (62, 18), (102, 28), (110, 62), (70, 72)], depth=0.55, stretch=(0.3, 1.0), facets=7, rough=False)
    r.chunk([(84, 70), (90, 50), (104, 46), (116, 58), (114, 72)], depth=0.5, facets=2, rough=False)
    r.render()
    r.ice(streaks=3)
    r.drift(4)
    return r.image()


ICE_TYPES = [
    ("ice_block", "Bloco de gelo", [lambda: ice_block(31), lambda: ice_block(37, snow=True)]),
    ("ice_spires", "Pináculos de gelo", [lambda: ice_spires(41)]),
    ("ice_arch", "Arco de gelo", [lambda: ice_arch(43)]),
    ("trapped_rock", "Rocha presa no gelo", [lambda: trapped_rock(47)]),
    ("icicle_block", "Bloco com sincelos", [lambda: icicle_block(53)]),
    ("ice_shelf", "Laje de gelo", [lambda: ice_shelf(59)]),
]

TYPES = [
    ("giant_crag", [lambda: crag(3), lambda: crag(11, moss=6), lambda: crag(21, GRANITE)]),
    ("giant_pinnacles", [lambda: pinnacles(5)]),
    ("giant_slab", [lambda: tilted_slab(7, moss=3)]),
    ("giant_boulders", [lambda: boulder_pile(9, moss=4)]),
    ("giant_ridge", [lambda: ridge(13)]),
    ("snowy_crag", [lambda: crag(19, GRANITE, snow=True)]),
    ("snowy_pinnacles", [lambda: pinnacles(17, GRANITE, snow=True)]),
    ("snowy_boulders", [lambda: boulder_pile(23, GRANITE, snow=True)]),
]


def preview(file):
    from PIL import ImageFont

    try:
        font = ImageFont.truetype("segoeui.ttf", 20)
    except OSError:
        font = ImageFont.load_default()
    floor = Image.open(os.path.join(HERE, "..", "terrain", "surfaces", "glacier.png")).convert("RGBA")
    tamer = Image.open(os.path.join(HERE, "..", "tamer", "bodies", "male", "idle.png")).convert("RGBA").crop((0, 0, 32, 32))
    rocks = [(name, number, len(variants), draw()) for _slug, name, variants in ICE_TYPES for number, draw in enumerate(variants, start=1)]
    rocks.append(("Rochedo com neve (para comparar)", 1, 1, crag(19, GRANITE, snow=True)))
    scale, cell_w, cell_h, columns = 3, 150, 140, 4
    rows = math.ceil(len(rocks) / columns)
    sheet = Image.new("RGBA", (cell_w * columns * scale, cell_h * rows * scale), (24, 30, 40, 255))
    text = ImageDraw.Draw(sheet)
    for index, (name, number, count, (img, blocks)) in enumerate(rocks):
        x = index * 37 % 300
        y = index * 53 % 300
        cell = floor.crop((x, y, x + cell_w, y + cell_h))
        foot = (cell_w // 2 - 12, cell_h - 12)
        cell.alpha_composite(img, (foot[0] - img.width // 2, foot[1] - img.height + 1))
        overlay = ImageDraw.Draw(cell)
        for points in blocks if isinstance(blocks[0], list) else [blocks]:
            pts = [(foot[0] + points[k], foot[1] + points[k + 1]) for k in range(0, len(points), 2)]
            overlay.line(pts + pts[:1], fill=(255, 80, 80, 200), width=1)
        cell.alpha_composite(tamer, (cell_w - 40, cell_h - 12 - 30))
        x0, y0 = (index % columns) * cell_w * scale, (index // columns) * cell_h * scale
        sheet.paste(cell.resize((cell_w * scale, cell_h * scale), Image.NEAREST), (x0, y0))
        label = name if count == 1 else f"{name} {number}"
        text.rectangle((x0, y0, x0 + 11 * len(label) + 12, y0 + 30), fill=(24, 30, 40, 220))
        text.text((x0 + 6, y0 + 3), label, fill=(230, 236, 244), font=font)
    sheet.convert("RGB").save(file)


def main():
    for slug, _name, variants in ICE_TYPES:
        os.makedirs(os.path.join(HERE, slug), exist_ok=True)
        for number, draw in enumerate(variants, start=1):
            img, block = draw()
            img.save(os.path.join(HERE, slug, f"{number}.png"))
            print(slug, number, img.size, block)
    for slug, variants in TYPES:
        os.makedirs(os.path.join(HERE, slug), exist_ok=True)
        for number, draw in enumerate(variants, start=1):
            img, block = draw()
            img.save(os.path.join(HERE, slug, f"{number}.png"))
            print(slug, number, img.size, block)


if __name__ == "__main__":
    if "--preview" in sys.argv:
        preview(sys.argv[sys.argv.index("--preview") + 1])
    else:
        main()
