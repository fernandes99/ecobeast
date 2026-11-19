"""Corta a imagem de uma linha evolutiva nos front.png de cada forma.

Uso, da raiz: python -I .claude/skills/creature-sprites/scripts/crop_line.py <imagem> <slug> [<slug> ...]

Os slugs vão da esquerda para a direita. Cada forma é a peça maior da coluna dela, e as
peças menores (folhas soltas, raios) vão para a forma de centro mais perto.

Uma imagem sem transparência, com o fundo de uma cor lisa (o verde #00FF00 do prompt da
skill creature-front-prompt), perde o fundo antes: a cor dos cantos e as próximas dela.
"""
import sys
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[4]
NOISE = 16
MIN_PIECE = 100
KEY = 100
EDGE = 170
SIDE = 480
CANVAS = 512


def pieces(alpha, w, h):
    seen = bytearray(w * h)
    found = []
    for y in range(h):
        for x in range(w):
            if alpha[x, y] <= NOISE or seen[y * w + x]:
                continue
            seen[y * w + x] = 1
            queue, pts = deque([(x, y)]), []
            while queue:
                cx, cy = queue.popleft()
                pts.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx] and alpha[nx, ny] > NOISE:
                        seen[ny * w + nx] = 1
                        queue.append((nx, ny))
            found.append(pts)
    return sorted((p for p in found if len(p) >= MIN_PIECE), key=len, reverse=True)


def key_background(src):
    w, h = src.size
    px = src.load()
    corners = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
    if any(c[3] < 255 for c in corners):
        return
    bg = tuple(sorted(c[i] for c in corners)[1] for i in range(3))

    def dist(c):
        return sum((c[i] - bg[i]) ** 2 for i in range(3)) ** 0.5

    keyed = set()
    for y in range(h):
        for x in range(w):
            if dist(px[x, y]) < KEY:
                px[x, y] = (0, 0, 0, 0)
                keyed.add((x, y))
    edge = []
    for x, y in keyed:
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] and dist(px[nx, ny]) < EDGE:
                edge.append((nx, ny))
    for p in edge:
        px[p] = (0, 0, 0, 0)


def box(pts):
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    return min(xs), min(ys), max(xs), max(ys)


def main(source, slugs):
    count = len(slugs)
    src = Image.open(source).convert("RGBA")
    key_background(src)
    w, h = src.size
    alpha = src.getchannel("A").load()
    found = pieces(alpha, w, h)
    bodies = sorted(found[:count], key=lambda p: box(p)[0])
    groups = [list(b) for b in bodies]
    for loose in found[count:]:
        cx = sum(p[0] for p in loose) / len(loose)
        groups[min(range(count), key=lambda i: abs((box(bodies[i])[0] + box(bodies[i])[2]) / 2 - cx))].extend(loose)
    for slug, pts in zip(slugs, groups):
        keep = Image.new("L", (w, h), 0)
        mask = keep.load()
        for x, y in pts:
            mask[x, y] = 255
        art = Image.new("RGBA", (w, h))
        art.paste(src, mask=keep)
        x0, y0, x1, y1 = box(pts)
        art = art.crop((x0, y0, x1 + 1, y1 + 1))
        scale = SIDE / max(art.size)
        art = art.resize((round(art.width * scale), round(art.height * scale)), Image.NEAREST)
        out = Image.new("RGBA", (CANVAS, CANVAS))
        out.paste(art, ((CANVAS - art.width) // 2, (CANVAS - art.height) // 2))
        dest = ROOT / "client/assets/creatures" / slug
        dest.mkdir(parents=True, exist_ok=True)
        out.save(dest / "front.png")
        print(slug, (x0, y0, x1, y1), art.size)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
