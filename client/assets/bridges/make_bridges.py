"""Recorta as pontes da folha Bridges.png do pacote da craftpix.net (bridges/05).

Uso: python -I make_bridges.py <Bridges.png> <pasta de saída>

Cada estilo vira uma pasta com duas vistas, cada uma em começo, meio que se repete e fim:
- a de cima (a ponte em pé): top_start.png, top_middle.png e top_end.png;
- a de lado (a ponte deitada): side_back_*.png (o corrimão de trás e o piso) e
  side_front_*.png (o corrimão da frente, já na altura certa, na mesma grade).
O jogo monta a ponte em qualquer ângulo e largura a partir delas (HexBridges).
"""

import os
import struct
import sys
import zlib

# Por estilo, em (x, y, largura, altura) na folha: as peças da vista de cima, de cima para
# baixo, e quantas linhas do fim são a cabeceira de baixo quando ela vem grudada no meio;
# e as da vista de lado: a de trás, a da frente e a montada, que diz onde a da frente fica.
STYLES = [
    {
        "slug": "rope_bridge",
        "top": [(227, 160, 26, 16), (227, 177, 26, 104), (227, 288, 26, 14)], "tail": 0,
        "back": [(273, 213, 15, 28), (293, 213, 103, 29), (400, 213, 15, 28)],
        "front": [(273, 261, 15, 14), (293, 261, 103, 14), (400, 261, 15, 14)],
        "joined": (293, 293, 103, 30),
    },
    {
        "slug": "wood_bridge",
        "top": [(225, 324, 29, 12), (225, 337, 29, 124)], "tail": 14,
        "back": [(272, 404, 16, 27), (292, 404, 103, 27), (400, 404, 16, 27)],
        "front": [(272, 441, 16, 15), (292, 441, 103, 15), (400, 441, 16, 15)],
        "joined": (292, 356, 103, 36),
        # O piso é contínuo: as linhas sem piso entre a cabeceira e o meio são o vão das
        # peças soltas do pacote, e saem. A sonda é a coluna (de cima) e a linha (de lado)
        # do meio do piso.
        "solid": (14, 16),
    },
]

CLEAR = (0, 0, 0, 0)


def close_gaps(lines, probe, caps):
    """Tira as linhas (ou colunas) sem piso no meio da ponte, entre a primeira e a última
    com piso, e devolve as que ficam e as cabeceiras ajustadas."""
    solid = [index for index, line in enumerate(lines) if line[probe][3] > 0]
    if not solid:
        return lines, caps
    first, last = solid[0], solid[-1]
    kept = []
    head, tail = caps
    for index, line in enumerate(lines):
        if first < index < last and line[probe][3] == 0:
            if index < caps[0]:
                head -= 1
            elif index >= len(lines) - caps[1]:
                tail -= 1
            continue
        kept.append(line)
    return kept, (head, tail)


def read_png(path):
    data = open(path, "rb").read()
    at = 8
    chunks = b""
    while at < len(data):
        size, = struct.unpack(">I", data[at:at + 4])
        kind = data[at + 4:at + 8]
        body = data[at + 8:at + 8 + size]
        if kind == b"IHDR":
            width, height, depth, color = struct.unpack(">IIBB", body[:10])
            assert depth == 8 and color == 6, "a folha precisa ser RGBA de 8 bits"
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
    width = len(pixels[0]) if height else 0
    raw = b"".join(b"\x00" + bytes(v for pixel in row for v in pixel) for row in pixels)

    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)

    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    with open(path, "wb") as out:
        out.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def crop(sheet, x, y, width, height):
    return [[sheet[y + j][x + i] if sheet[y + j][x + i][3] > 0 else CLEAR for i in range(width)] for j in range(height)]


def mismatch(lines, one, other):
    """A fração de pixels diferentes entre duas linhas (ou colunas)."""
    a, b = lines[one], lines[other]
    return sum(1 for i in range(len(a)) if a[i] != b[i]) / float(len(a))


def split(lines, caps):
    """Começo, meio que se repete e fim de uma sequência de linhas (ou colunas). O meio é o
    trecho de 16 a 64 linhas, dentro da peça do meio, que emenda melhor com ele mesmo;
    o fim começa um número inteiro de períodos depois, para a emenda cair no mesmo ponto.
    caps é quantas linhas das pontas vieram das cabeceiras separadas."""
    head, tail = caps
    first = head + 4
    last = len(lines) - tail - 4
    best = None
    for period in (16, 24, 32, 40, 48, 64):
        for start in range(first, min(last - period, first + 40)):
            cost = mismatch(lines, start, start + period)
            cost += mismatch(lines, start + period - 1, start - 1)
            if best is None or cost < best[0] - 0.02 or (cost <= best[0] + 0.02 and period < best[1] and cost < 0.2):
                best = (cost, period, start)
    if best is None:
        return lines[:head], lines[head:len(lines) - tail], lines[len(lines) - tail:]
    cost, period, start = best
    end = start + period
    while end + period <= last:
        end += period
    return lines[:start], lines[start:start + period], lines[end:]


def columns(pixels):
    return [tuple(row[i] for row in pixels) for i in range(len(pixels[0]))]


def from_columns(cols):
    return [[col[j] for col in cols] for j in range(len(cols[0]))]


def side_strip(sheet, boxes, band, spans):
    """As colunas de uma vista de lado: cabeceira, meio e cabeceira, todas na faixa de
    linhas `band` da folha e nas faixas de colunas `spans`."""
    cols = []
    for span in spans:
        cols += columns(crop(sheet, span[0], band[0], span[1] - span[0], band[1] - band[0]))
    return cols


def front_offset(sheet, style):
    """Quantas linhas abaixo do topo da peça de trás o corrimão da frente fica, pela
    montada."""
    joined, back, front = style["joined"], style["back"][1], style["front"][1]
    target = crop(sheet, joined[0], joined[1], joined[2], joined[3])
    behind = crop(sheet, joined[0], back[1], joined[2], back[3])
    ahead = crop(sheet, joined[0], front[1], joined[2], front[3])
    best = (-1, 0)
    for shift in range(-front[3], joined[3]):
        score = 0
        for j in range(joined[3]):
            for i in range(0, joined[2], 3):
                pixel = behind[j][i] if j < len(behind) and behind[j][i][3] > 0 else CLEAR
                k = j - shift
                if 0 <= k < len(ahead) and ahead[k][i][3] > 0:
                    pixel = ahead[k][i]
                score += pixel == target[j][i]
        if score > best[0]:
            best = (score, shift)
    return best[1]


def make_side(sheet, style, folder):
    spans = []
    for index in range(3):
        boxes = [style[key][index] for key in ("back", "front")]
        spans.append((min(box[0] for box in boxes), max(box[0] + box[2] for box in boxes)))
    back_band = (min(box[1] for box in style["back"]), max(box[1] + box[3] for box in style["back"]))
    front_band = (min(box[1] for box in style["front"]), max(box[1] + box[3] for box in style["front"]))
    back = side_strip(sheet, style["back"], back_band, spans)
    front = side_strip(sheet, style["front"], front_band, spans)
    shift = front_offset(sheet, style) + style["back"][1][1] - back_band[0]
    height = max(back_band[1] - back_band[0], shift + front_band[1] - front_band[0])
    joined = []
    for i in range(len(back)):
        back_col = list(back[i]) + [CLEAR] * (height - len(back[i]))
        front_col = [CLEAR] * height
        for j, pixel in enumerate(front[i]):
            if 0 <= shift + j < height:
                front_col[shift + j] = pixel
        joined.append(tuple(back_col) + tuple(front_col))
    caps = (spans[0][1] - spans[0][0], spans[2][1] - spans[2][0])
    if "solid" in style:
        joined, caps = close_gaps(joined, style["solid"][1], caps)
    start, middle, end = split(joined, caps)
    for name, part in (("start", start), ("middle", middle), ("end", end)):
        write_png(os.path.join(folder, "side_back_%s.png" % name), from_columns([col[:height] for col in part]))
        write_png(os.path.join(folder, "side_front_%s.png" % name), from_columns([col[height:] for col in part]))
    return "lado %d de altura, colunas %d+%d+%d, frente +%d" % (height, len(start), len(middle), len(end), shift)


def make(sheet_path, out_dir):
    sheet = read_png(sheet_path)
    for style in STYLES:
        folder = os.path.join(out_dir, style["slug"])
        os.makedirs(folder, exist_ok=True)
        boxes = style["top"]
        x0 = min(box[0] for box in boxes)
        x1 = max(box[0] + box[2] for box in boxes)
        rows = []
        for box in boxes:
            rows += [tuple(row) for row in crop(sheet, x0, box[1], x1 - x0, box[3])]
        head = boxes[0][3]
        tail = boxes[2][3] if len(boxes) > 2 else style["tail"]
        caps = (head, tail)
        if "solid" in style:
            rows, caps = close_gaps(rows, style["solid"][0], caps)
        start, middle, end = split(rows, caps)
        for name, part in (("start", start), ("middle", middle), ("end", end)):
            write_png(os.path.join(folder, "top_%s.png" % name), [list(row) for row in part])
        side = make_side(sheet, style, folder)
        print("%s: cima %d de largura, linhas %d+%d+%d; %s" % (style["slug"], x1 - x0, len(start), len(middle), len(end), side))


if __name__ == "__main__":
    make(sys.argv[1], sys.argv[2])
