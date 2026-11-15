"""Recorta as paredes das folhas dos pacotes (fence-art/01, home-pack/02): a cerca de madeira e o
muro de pedra do Sunnyside World e a cerca de estacas do Main Characters Home.

Uso: python -I make_walls.py <spr_tileset_sunnysideworld_16px.png> <exterior.png> <pasta de saída>

Cada parede vira uma folha de 3 células de 96x72, com o pé em (48, 43), que o HexWalls lê:
- 0: o poste (ou o pilar), com o pé no pé da célula;
- 1: a travessa deitada entre dois postes, nas colunas 0 a 15 (a coluna 0 é o meio de um
  poste; a cerca de estacas usa só as 8 primeiras), com a linha do chão na linha do pé;
- 2: a travessa vista de cima, das linhas 0 em diante, centrada na coluna 48.
"""

import os
import struct
import sys
import zlib

CELL = (96, 72)
FOOT = (48, 43)
SPAN = 16
CLEAR = (0, 0, 0, 0)


def color(hex_code):
    return tuple(int(hex_code[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


# Por parede: a folha (0 a do Sunnyside, 1 a do Main Characters Home), o poste (x, y,
# largura, altura, coluna e linha do pé), os pixels do poste que saem (x, y na folha), a
# unidade da travessa (x, y, altura, linha do pé, a coluna do meio do poste e as colunas
# que são travessa; as outras, por baixo do poste, repetem a coluna lisa) e a travessa
# vista de cima, em cores ou num retângulo da folha (x, y, largura, altura).
WALLS = [
    {
        "slug": "wood_fence",
        "sheet": 0,
        "post": (613, 0, 6, 11, 3, 9),
        "rail": (613, 0, 11, 9, 3, range(6, 16), 10),
        "top": [[color(c) for c in ("9a5a43", "e2b78a", "e2b78a", "9a5a43")]],
    },
    {
        "slug": "stone_fence",
        "sheet": 0,
        "post": (724, 48, 8, 17, 4, 14),
        "rail": (720, 48, 17, 14, 8, (12, 13, 14, 15, 16, 17, 18, 19), 2),
        "top": [[color({"a": "5a6988", "b": "8b9bb4", "c": "c0cbdc"}[c]) for c in row]
                for row in ["abccccba"] * 7 + ["aaaaaaaa"]],
    },
    {
        "slug": "picket_fence",
        "sheet": 1,
        "post": (177, 16, 7, 16, 3, 14),
        "clear": [(x, y) for x in (177, 183) for y in (22, 23, 24)],
        "rail": (177, 16, 16, 14, 3, (7,), 7),
        "top": (169, 25, 7, 8),
    },
]


def read_png(path):
    data = open(path, "rb").read()
    at = 8
    chunks = b""
    while at < len(data):
        size, = struct.unpack(">I", data[at:at + 4])
        kind = data[at + 4:at + 8]
        body = data[at + 8:at + 8 + size]
        if kind == b"IHDR":
            width, height, depth, color_type = struct.unpack(">IIBB", body[:10])
            assert depth == 8 and color_type == 6, "a folha precisa ser RGBA de 8 bits"
        elif kind == b"IDAT":
            chunks += body
        at += 12 + size
    raw = zlib.decompress(chunks)
    stride = width * 4
    rows = []
    previous = bytearray(stride)
    offset = 0
    for _ in range(height):
        kind = raw[offset]
        offset += 1
        line = bytearray(raw[offset:offset + stride])
        offset += stride
        for x in range(stride):
            left = line[x - 4] if x >= 4 else 0
            up = previous[x]
            corner = previous[x - 4] if x >= 4 else 0
            if kind == 1:
                line[x] = (line[x] + left) & 255
            elif kind == 2:
                line[x] = (line[x] + up) & 255
            elif kind == 3:
                line[x] = (line[x] + (left + up) // 2) & 255
            elif kind == 4:
                guess = left + up - corner
                a, b, c = abs(guess - left), abs(guess - up), abs(guess - corner)
                pick = left if a <= b and a <= c else (up if b <= c else corner)
                line[x] = (line[x] + pick) & 255
        rows.append([tuple(line[x * 4:x * 4 + 4]) for x in range(width)])
        previous = line
    return rows


def write_png(path, pixels):
    height = len(pixels)
    width = len(pixels[0])
    raw = b"".join(b"\x00" + bytes(v for pixel in row for v in pixel) for row in pixels)

    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)

    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    with open(path, "wb") as out:
        out.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def pixel(sheet, x, y):
    value = sheet[y][x]
    return value if value[3] > 0 else CLEAR


def sheet_for(sheet, wall):
    out = [[CLEAR] * (CELL[0] * 3) for _ in range(CELL[1])]
    x, y, width, height, foot_x, foot_y = wall["post"]
    clear = wall.get("clear", [])
    for j in range(height):
        for i in range(width):
            value = CLEAR if (x + i, y + j) in clear else pixel(sheet, x + i, y + j)
            out[FOOT[1] - foot_y + j][FOOT[0] - foot_x + i] = value
    x, y, height, foot_y, middle, columns, plain = wall["rail"]
    for column in range(SPAN):
        source = middle + column
        source = source if source in columns else plain
        for j in range(height):
            out[FOOT[1] - foot_y + j][CELL[0] + column] = pixel(sheet, x + source, y + j)
    top = wall["top"]
    if isinstance(top, tuple):
        x, y, width, height = top
        top = [[pixel(sheet, x + i, y + j) for i in range(width)] for j in range(height)]
    left = CELL[0] * 2 + FOOT[0] - len(top[0]) // 2
    for j, row in enumerate(top):
        for i, value in enumerate(row):
            out[j][left + i] = value
    return out


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    sheets = [read_png(sys.argv[1]), read_png(sys.argv[2])]
    for wall in WALLS:
        path = os.path.join(sys.argv[3], wall["slug"] + ".png")
        write_png(path, sheet_for(sheets[wall["sheet"]], wall))
        print(path)


main()
