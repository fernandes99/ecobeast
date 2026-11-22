"""Monta os prédios da Arena com os tiles do Fantasy Dreamland Reborn (arena-buildings/01).

Uso: python -I make_arena.py <pasta Tilesets do pacote> [--preview <arquivo.png>]
(precisa do Pillow; roda de dentro de assets/props)

A fortaleza junta a muralha com ameias, a grade levadiça, os estandartes e o braseiro do
Castle. O coliseu estica o anel octogonal do Dungeon, com a areia dentro (variante 1) ou
coberto de lajes (variante 2), e desenha a parede de fora da frente com o tijolo do Dungeon.
Grava arena_fortress/1.png e arena_coliseum/1.png e 2.png, o quadro 0, e <variante>_frames.png,
os 8 quadros do braseiro lado a lado (HexMapView.PROP_FRAMES), e imprime o bloqueio e as luzes
de cada variante, em pixels a partir do pé.
"""

import os
import sys
from collections import deque

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
FRAMES = 8
# o bloco de muralha com ameias no Castle: colunas e faixas (y, altura) de cima para baixo
CRENEL_COLS = (128, 144, 160)
CRENEL_TOP, CRENEL_DEPTH, CRENEL_FRONT, CRENEL_FACE, CRENEL_BASE = (29, 19), (48, 16), (64, 16), (80, 16), (96, 16)
CASTLE_FLOOR = (112, 0)
CASTLE_SLAB = (16, 0)
CASTLE_PLAQUE = (160, 176)
CASTLE_WINDOW = (0, 160, 16, 16)
CASTLE_TALL_WINDOW = (16, 224, 16, 32)
CASTLE_BANNER_Y = 195
CASTLE_STAIRS = (148, 168, 192, 214)
# o octógono do Dungeon: a caixa recortada, as colunas que esticam e a linha que repete
OCTAGON = (100, 30, 72, 78)
OCT_LEFT, OCT_MID, OCT_RIGHT = 106, 128, 144
OCT_SPLIT, OCT_BOTTOM = 80, 104
OCT_TOP = 33
DUNGEON_WALL = (128, 40, 56)
DUNGEON_SAND = ((32, 0), (48, 0))
DUNGEON_PLATE = (80, 16)
DUNGEON_BANNER_Y, DUNGEON_TORN_Y = 199, 232
SWORD, SHIELD = 64, 80


class Pack:
    def __init__(self, root):
        def load(path):
            return Image.open(os.path.join(root, path)).convert("RGBA")

        self.castle = load("Castle/Sprites/FDR_Castle_Tiles.png")
        self.torch = load("Castle/Sprites/FDR_Castle_Torches.png")
        self.gate = load("Castle/Sprites/FDR_Castle_Door05.png")
        self.dungeon = load("Dungeon/Sprites/FDR_Dungeon.png")


def crop(sheet, x, y, w, h):
    return sheet.crop((x, y, x + w, y + h))


def paste(dst, src, x, y):
    dst.alpha_composite(src, (x, y))


def brazier(pack, frame):
    return crop(pack.torch, 16 * frame, 0, 16, 32)


def crenel_box(pack, w, depth, face):
    """a muralha com ameias de w tiles, depth linhas de topo e face linhas de tijolo"""
    out = Image.new("RGBA", (w * 16, 19 + 16 * depth + 16 + 16 * face + 16))
    floor = crop(pack.castle, *CASTLE_FLOOR, 16, 16)
    for ty in range(0, 16 * (depth + 2), 16):
        for tx in range(0, out.width, 16):
            paste(out, floor, tx, 8 + ty)
    rows = [CRENEL_TOP] + [CRENEL_DEPTH] * depth + [CRENEL_FRONT] + [CRENEL_FACE] * face + [CRENEL_BASE]
    cols = [CRENEL_COLS[0]] + [CRENEL_COLS[1]] * (w - 2) + [CRENEL_COLS[2]]
    y = 0
    for sy, sh in rows:
        for i, sx in enumerate(cols):
            paste(out, crop(pack.castle, sx, sy, 16, sh), i * 16, y)
        y += sh
    return out


def fortress(pack, frame):
    """devolve a imagem, o bloqueio e as luzes, em pixels da imagem"""
    tower = crenel_box(pack, 3, 1, 5)
    wall = crenel_box(pack, 3, 0, 3)
    gatehouse = crenel_box(pack, 5, 0, 4)
    W, H = 240, tower.height + 14
    base = H - 14
    out = Image.new("RGBA", (W, H))
    for wx in (40, W - 88):
        paste(out, wall, wx, base - 6 - wall.height)
    window = crop(pack.castle, *CASTLE_WINDOW)
    for wx in (56, W - 72):
        paste(out, window, wx, base - 44)
    tall = crop(pack.castle, *CASTLE_TALL_WINDOW)
    for tx in (0, W - 48):
        paste(out, tower, tx, base - tower.height)
        paste(out, crop(pack.castle, 80, CASTLE_BANNER_Y, 16, 26), tx + 16, base - tower.height + 61)
        paste(out, tall, tx + 16, base - 50)
    gx, gy = (W - 80) // 2, base + 4 - gatehouse.height
    paste(out, gatehouse, gx, gy)
    paste(out, crop(pack.gate, 0, 0, 48, 32), gx + 16, gy + gatehouse.height - 32)
    paste(out, crop(pack.castle, *CASTLE_PLAQUE, 16, 16), gx + 32, gy + 39)
    for bx, sx in ((gx + 2, 96), (gx + 62, 112)):
        paste(out, crop(pack.castle, sx, CASTLE_BANNER_Y, 16, 26), bx, gy + 41)
    fires = [gx - 14, gx + 78]
    for fx in fires:
        paste(out, brazier(pack, frame), fx, H - 32)
    block = [(0, base), (48, base), (48, base - 6), (fires[0], base - 6), (fires[0], H - 2),
             (fires[0] + 16, H - 2), (fires[0] + 16, base + 4), (fires[1], base + 4), (fires[1], H - 2),
             (fires[1] + 16, H - 2), (fires[1] + 16, base - 6), (W - 48, base - 6), (W - 48, base),
             (W, base), (W, base - 51), (0, base - 51)]
    lights = [(fx + 8, H - 18) for fx in fires]
    return out, block, lights


def unvoid(image):
    """o octógono vem num fundo escuro de masmorra: apaga o escuro ligado à borda"""
    image = image.copy()
    px = image.load()
    W, H = image.size
    void = px[W - 1, H - 1][:3]
    queue = deque([(x, y) for x in range(W) for y in (0, H - 1)] + [(x, y) for y in range(H) for x in (0, W - 1)])
    seen = set()
    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or not (0 <= x < W and 0 <= y < H):
            continue
        seen.add((x, y))
        if px[x, y][3] == 0 or px[x, y][:3] == void:
            px[x, y] = (0, 0, 0, 0)
            queue.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])
    return image


def widened_octagon(pack, extra):
    """o octógono com a coluna do meio repetida extra + 1 vezes, na altura do Dungeon"""
    ox, oy = OCTAGON[0], OCTAGON[1]
    octagon = unvoid(crop(pack.dungeon, *OCTAGON))
    side = OCT_MID - OCT_LEFT
    left = crop(octagon, OCT_LEFT - ox, 0, side, octagon.height)
    mid = crop(octagon, OCT_MID - ox, 0, 16, octagon.height)
    right = crop(octagon, OCT_RIGHT - ox, 0, side, octagon.height)
    W = 2 * side + 16 * (extra + 1)
    wide = Image.new("RGBA", (W, octagon.height))
    paste(wide, left, 0, 0)
    for i in range(extra + 1):
        paste(wide, mid, side + 16 * i, 0)
    paste(wide, right, W - side, 0)
    return wide, oy


def ring(pack, extra, grow):
    """o anel visto por dentro, esticado: a linha OCT_SPLIT só tem os lados retos e repete"""
    wide, oy = widened_octagon(pack, extra)
    W = wide.width
    top = wide.crop((0, OCT_TOP - oy, W, OCT_SPLIT - oy))
    row = wide.crop((0, OCT_SPLIT - oy, W, OCT_SPLIT + 1 - oy))
    bottom = wide.crop((0, OCT_SPLIT + 1 - oy, W, OCT_BOTTOM - oy))
    out = Image.new("RGBA", (W, top.height + grow + bottom.height))
    paste(out, top, 0, 0)
    for i in range(grow):
        paste(out, row, 0, top.height + i)
    paste(out, bottom, 0, top.height + grow)
    return out


def rim(pack, extra, height):
    """o anel só de moldura, para o fechado: a borda de baixo espelhada em cima"""
    wide, oy = widened_octagon(pack, extra)
    W = wide.width
    bottom = wide.crop((0, OCT_SPLIT + 1 - oy, W, OCT_BOTTOM - oy))
    row = wide.crop((0, OCT_SPLIT - oy, W, OCT_SPLIT + 1 - oy))
    out = Image.new("RGBA", (W, height))
    paste(out, bottom.transpose(Image.FLIP_TOP_BOTTOM), 0, 0)
    for y in range(bottom.height, height - bottom.height):
        paste(out, row, 0, y)
    paste(out, bottom, 0, height - bottom.height)
    return out


def wall_column(pack, x, height):
    """uma coluna da parede norte do Dungeon com height px: o tijolo repete e o rodapé fecha"""
    sx, brick_top, base_top = DUNGEON_WALL[0] + x % 16, DUNGEON_WALL[1], DUNGEON_WALL[2]
    column = Image.new("RGBA", (1, height))
    brick = crop(pack.dungeon, sx, brick_top, 1, base_top - brick_top)
    y = 0
    while y < height - 8:
        paste(column, brick, 0, y)
        y += brick.height
    paste(column, crop(pack.dungeon, sx, base_top, 1, 8), 0, height - 8)
    return column


def hang_front(pack, out, shape, face):
    """a parede de fora: cada coluna desce do pé da borda de baixo do anel"""
    alpha = shape.getchannel("A").load()
    for x in range(shape.width):
        ys = [y for y in range(shape.height // 2, shape.height) if alpha[x, y] > 0]
        if ys:
            paste(out, wall_column(pack, x, face), x, max(ys))


def inside(shape):
    """a máscara do buraco do anel"""
    W, H = shape.size
    mask = Image.new("L", (W + 2, H + 2), 0)
    mask.paste(shape.getchannel("A"), (1, 1))
    ImageDraw.floodfill(mask, (0, 0), 128)
    return mask.crop((1, 1, W + 1, H + 1)).point(lambda v: 255 if v == 0 else 0)


def tiled(sheet, tiles, size):
    out = Image.new("RGBA", size)
    for ty in range(0, size[1], 16):
        for tx in range(0, size[0], 16):
            sx, sy = tiles[(tx // 16 + ty // 16) % len(tiles)]
            paste(out, crop(sheet, sx, sy, 16, 16), tx, ty)
    return out


def coliseum(pack, frame, closed):
    extra, grow = 9, 50
    face = 56 if closed else 40
    open_ring = ring(pack, extra, grow)
    W, H = open_ring.size
    shape = rim(pack, extra, H) if closed else open_ring
    out = Image.new("RGBA", (W, H + face))
    hole = inside(shape)
    if closed:
        floor = tiled(pack.castle, [CASTLE_SLAB], (W, H))
    else:
        floor = tiled(pack.dungeon, DUNGEON_SAND, (W, H))
    hang_front(pack, out, shape, face)
    out.paste(floor, (0, 0), hole)
    paste(out, shape, 0, 0)
    gx = (W - 48) // 2
    paste(out, crop(pack.gate, 0, 0, 48, 32), gx, out.height - 33)
    if closed:
        paste(out, crop(pack.castle, *CASTLE_PLAQUE, 16, 16), W // 2 - 8, out.height - 51)
        for bx, sx, flip in ((gx - 40, SWORD, False), (gx + 72, SWORD, True)):
            banner = crop(pack.dungeon, sx, DUNGEON_BANNER_Y, 16, 19)
            paste(out, banner.transpose(Image.FLIP_LEFT_RIGHT) if flip else banner, bx, H + 10)
    else:
        sx0, sx1, step_x, step_y = CASTLE_STAIRS
        stand = Image.new("RGBA", (W - 44, 20))
        for x in range(0, stand.width, 16):
            paste(stand, crop(pack.castle, sx1, step_y, 16, 20), x, 0)
        paste(stand, crop(pack.castle, sx0, step_y, 12, 20), 0, 0)
        paste(stand, crop(pack.castle, step_x, step_y, 12, 20), stand.width - 12, 0)
        paste(out, stand, 22, 31)
        for bx, sx, flip in ((W // 2 - 52, SWORD, False), (W // 2 - 26, SHIELD, False),
                             (W // 2 + 10, SHIELD, False), (W // 2 + 36, SWORD, True)):
            banner = crop(pack.dungeon, sx, DUNGEON_TORN_Y, 16, 19)
            paste(out, banner.transpose(Image.FLIP_LEFT_RIGHT) if flip else banner, bx, 8)
        paste(out, crop(pack.dungeon, *DUNGEON_PLATE, 16, 16), W // 2 - 8, 51 + (H - 51) // 2 - 12)
    fires = [gx - 18, gx + 50]
    for fx in fires:
        paste(out, brazier(pack, frame), fx, out.height - 30)
    bottom = out.height - 2
    top = face
    corner = 22
    block = [(corner, top), (W - corner, top), (W, top + corner), (W, bottom - corner),
             (W - corner, bottom), (corner, bottom), (0, bottom - corner), (0, top + corner)]
    lights = [(fx + 8, out.height - 16) for fx in fires]
    return out, block, lights


def from_foot(image, points):
    half, height = image.width // 2, image.height
    return [(x - half, y - height) for x, y in points]


BUILDINGS = {
    "arena_fortress": [lambda pack, frame: fortress(pack, frame)],
    "arena_coliseum": [lambda pack, frame: coliseum(pack, frame, False),
                       lambda pack, frame: coliseum(pack, frame, True)],
}


def preview(pack, path):
    images = [make(pack, 0)[0] for makers in BUILDINGS.values() for make in makers]
    refuge = Image.open(os.path.join(HERE, "refuge_building", "1.png")).convert("RGBA")
    images.append(refuge)
    gap = 24
    H = max(i.height for i in images) + 40
    sheet = Image.new("RGBA", (sum(i.width for i in images) + gap * (len(images) + 1), H), (96, 150, 72, 255))
    x = gap
    for image in images:
        sheet.alpha_composite(image, (x, H - 20 - image.height))
        x += image.width + gap
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(path)


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    pack = Pack(sys.argv[1])
    if "--preview" in sys.argv:
        preview(pack, sys.argv[sys.argv.index("--preview") + 1])
        return
    for slug, makers in BUILDINGS.items():
        folder = os.path.join(HERE, slug)
        os.makedirs(folder, exist_ok=True)
        for variant, make in enumerate(makers, start=1):
            frames = [make(pack, frame) for frame in range(FRAMES)]
            first, block, lights = frames[0]
            first.save(os.path.join(folder, f"{variant}.png"))
            sheet = Image.new("RGBA", (first.width * FRAMES, first.height))
            for i, (image, _, _) in enumerate(frames):
                sheet.alpha_composite(image, (i * first.width, 0))
            sheet.save(os.path.join(folder, f"{variant}_frames.png"))
            print(slug, variant, first.size)
            print("  bloqueio", [c for p in from_foot(first, block) for c in p])
            print("  luzes", from_foot(first, lights))


if __name__ == "__main__":
    main()
