"""Base das folhas de pixel art dos Ecobeasts, só com a biblioteca padrão do Python.

Um desenho é uma lista de textos, com um caractere por pixel: `.` é transparente, e os
outros são chaves da paleta da criatura. A folha de cada criatura sai de um `sprites.py`
em `<slug>/explore/`, ao lado das folhas, que chama `build`.
"""
import struct
import zlib
from pathlib import Path

CELL = 32
# A mesma ordem de assets/tamer: o lado esquerdo sai espelhando no jogo.
VIEWS = ("front", "lower", "side", "upper", "back")
FRAMES = {"idle": 4, "walk": 6}
# A escala de tudo no mapa: o Domador tem 1,70 m e ocupa 25 pixels da folha.
TAMER_HEIGHT_M = 1.70
TAMER_HEIGHT_PX = 25
GROUND = (204, 204, 204)


def height_in_pixels(height_m):
    """Quantos pixels de altura um Ecobeast tem, na escala do Domador."""
    return round(height_m * TAMER_HEIGHT_PX / TAMER_HEIGHT_M)


def read_png(path):
    """(largura, altura, linhas), com cada linha em RGBA. Aceita PNG de 8 bits, RGB ou RGBA."""
    return read_png_bytes(Path(path).read_bytes())


def read_png_bytes(data):
    """Como `read_png`, a partir do conteúdo do arquivo (por exemplo, de dentro de um zip)."""
    pos = 8
    idat = b""
    width = height = channels = 0
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        tag = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + length]
        if tag == b"IHDR":
            width, height, depth, color, _, _, interlace = struct.unpack(">IIBBBBB", body)
            if depth != 8 or color not in (2, 6) or interlace != 0:
                raise ValueError("PNG sem suporte: profundidade %d, cor %d, entrelaçado %d" % (depth, color, interlace))
            channels = 4 if color == 6 else 3
        elif tag == b"IDAT":
            idat += body
        pos += 12 + length
    raw = zlib.decompress(idat)
    stride = width * channels
    previous = bytearray(stride)
    rows = []
    pos = 0
    for _ in range(height):
        kind = raw[pos]
        line = bytearray(raw[pos + 1:pos + 1 + stride])
        pos += 1 + stride
        for i in range(stride):
            left = line[i - channels] if i >= channels else 0
            up = previous[i]
            corner = previous[i - channels] if i >= channels else 0
            if kind == 1:
                line[i] = (line[i] + left) & 255
            elif kind == 2:
                line[i] = (line[i] + up) & 255
            elif kind == 3:
                line[i] = (line[i] + (left + up) // 2) & 255
            elif kind == 4:
                guess = left + up - corner
                near_left, near_up, near_corner = abs(guess - left), abs(guess - up), abs(guess - corner)
                best = left if near_left <= near_up and near_left <= near_corner else up if near_up <= near_corner else corner
                line[i] = (line[i] + best) & 255
        previous = line
        if channels == 4:
            rows.append(bytes(line))
        else:
            rows.append(b"".join(bytes(line[i:i + 3]) + b"\xff" for i in range(0, stride, 3)))
    return width, height, rows


def write_png(path, width, height, rows):
    def chunk(tag, body):
        return struct.pack(">I", len(body)) + tag + body + struct.pack(">I", zlib.crc32(tag + body))

    raw = b"".join(b"\0" + row for row in rows)
    Path(path).write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


def mirrored(rows):
    """Espelha a metade esquerda em torno da coluna do meio, que é o último caractere."""
    return [row + row[-2::-1] for row in rows]


def recolored(drawing, before, after):
    """O mesmo desenho com outras cores: o rosto vira pelo na vista de costas."""
    table = str.maketrans(before, after)
    return [row.translate(table) for row in drawing]


def swayed(drawing, amounts=(0, 1, 0, -1)):
    """Um quadro por valor, com o topo deslocado e a base presa: serve para chama e folha.

    Cada linha ganha uma coluna vazia de cada lado por pixel de deslocamento: desconte isso
    da coluna em que a parte é carimbada.
    """
    pad = max(abs(amount) for amount in amounts)
    last = max(len(drawing) - 1, 1)
    frames = []
    for amount in amounts:
        frame = []
        for j, row in enumerate(drawing):
            shift = round(amount * (last - j) / last)
            frame.append("." * (pad + shift) + row + "." * (pad - shift))
        frames.append(frame)
    return frames


class Canvas:
    """Uma célula da folha. Sair da célula é erro: um pixel cortado não aparece em lugar nenhum."""

    def __init__(self, palette):
        self.palette = palette
        self.pixels = [[None] * CELL for _ in range(CELL)]

    def stamp(self, drawing, left, top):
        for j, row in enumerate(drawing):
            for i, mark in enumerate(row):
                if mark == ".":
                    continue
                x, y = left + i, top + j
                if not (0 <= x < CELL and 0 <= y < CELL):
                    raise ValueError("pixel %r fora da célula em (%d, %d)" % (mark, x, y))
                self.pixels[y][x] = self.palette[mark]


def draw_leg(canvas, style, hip, top, reach, lift):
    """Uma pata: `style` tem uma linha por altura. O pé vai `reach` à frente do quadril e sobe `lift`."""
    last = max(len(style) - 1, 1)
    for index, row in enumerate(style):
        shift = round(reach * index / last) if len(style) > 1 else reach
        canvas.stamp([row], hip + shift, top + index - round(lift * index / last))


def rig(heads, bodies, legs, legs_top, traits=(), idle_head=(0, 1, 2, 0), idle_body=(0, 1, 1, 0), walk_head=(1, 1, 0, 1, 1, 0), walk_body=(1, 0, 0, 1, 0, 0), foot_reach=(2, 1, -1, -2, -1, 1), foot_lift=(0, 0, 0, 0, 2, 1), walk_traits=(0, 1, 2, 3, 2, 1)):
    """Monta as funções de desenho de uma criatura, para entregar a `build`.

    heads e bodies: {ângulo: (desenho, coluna, linha)}; um corpo pode ficar de fora.
    legs: {ângulo: [(coluna do quadril, ponto do ciclo, estilo, alcance)]}, de trás para a frente.
    traits: traços marcantes, em ordem. Cada um é um dicionário com `frames` (4 desenhos, ou
    {ângulo: 4 desenhos}), `at` ({ângulo: (coluna, linha)}), `follows` ("head", "body" ou
    nada) e, se preciso, `behind` (ângulos em que fica atrás de tudo) e `walk` (quadros do walk).
    """

    def draw(canvas, view, head_drop, body_drop, frame, draw_legs, walking):
        drops = {"head": head_drop, "body": body_drop, None: 0}

        def stamp_trait(trait):
            if view not in trait["at"]:
                return
            frames = trait["frames"]
            frames = frames[view] if isinstance(frames, dict) else frames
            index = trait.get("walk", walk_traits)[frame] if walking else frame
            left, top = trait["at"][view]
            canvas.stamp(frames[index], left, top + drops[trait.get("follows")])

        for trait in traits:
            if view in trait.get("behind", ()):
                stamp_trait(trait)
        draw_legs()
        if view in bodies:
            drawing, left, top = bodies[view]
            canvas.stamp(drawing, left, top + body_drop)
        drawing, left, top = heads[view]
        canvas.stamp(drawing, left, top + head_drop)
        for trait in traits:
            if view not in trait.get("behind", ()):
                stamp_trait(trait)

    def draw_idle(canvas, view, frame):
        def stand():
            for hip, _phase, style, _reach in legs[view]:
                draw_leg(canvas, style, hip, legs_top, 0, 0)

        draw(canvas, view, idle_head[frame], idle_body[frame], frame, stand, False)

    def draw_walk(canvas, view, frame):
        def step():
            for hip, phase, style, reach in legs[view]:
                point = (frame + phase) % 6
                draw_leg(canvas, style, hip, legs_top, foot_reach[point] * reach, foot_lift[point])

        draw(canvas, view, walk_head[frame], walk_body[frame], frame, step, True)

    return {"idle": draw_idle, "walk": draw_walk}


def _sheet_rows(cells, frames):
    rows = []
    for view in range(len(VIEWS)):
        for y in range(CELL):
            line = bytearray()
            for frame in range(frames):
                for pixel in cells[view][frame][y]:
                    line += bytes(pixel + (255,)) if pixel else b"\0\0\0\0"
            rows.append(bytes(line))
    return rows


def _opaque(pixel):
    return pixel if pixel else GROUND


def _save_preview(path, cells, frames, zoom=6):
    rows = []
    for view in range(len(VIEWS)):
        for y in range(CELL):
            line = bytearray()
            for frame in range(frames):
                for x, pixel in enumerate(cells[view][frame][y]):
                    grid = x == 0 or y == 0
                    color = pixel if pixel else ((184, 184, 184) if grid else GROUND)
                    line += bytes(color + (255,)) * zoom
            for _ in range(zoom):
                rows.append(bytes(line))
    write_png(path, CELL * frames * zoom, len(rows), rows)


def _lzw(indices, minimum=8):
    clear = 1 << minimum
    end = clear + 1

    def fresh():
        return {bytes((i,)): i for i in range(clear)}, end + 1, minimum + 1

    table, next_code, size = fresh()
    bits = 0
    filled = 0
    output = bytearray()

    def emit(code):
        nonlocal bits, filled
        bits |= code << filled
        filled += size
        while filled >= 8:
            output.append(bits & 255)
            bits >>= 8
            filled -= 8

    emit(clear)
    current = b""
    for index in indices:
        grown = current + bytes((index,))
        if grown in table:
            current = grown
            continue
        emit(table[current])
        if next_code < 4096:
            table[grown] = next_code
            next_code += 1
            if next_code > (1 << size) and size < 12:
                size += 1
        else:
            emit(clear)
            table, next_code, size = fresh()
        current = bytes((index,))
    if current:
        emit(table[current])
    emit(end)
    if filled:
        output.append(bits & 255)
    return bytes(output)


def _save_gif(path, cells, frames, delay, zoom=4):
    """Todos os ângulos lado a lado, animados: o jeito de ver o movimento fora do jogo."""
    colors = [GROUND]
    index_of = {GROUND: 0}
    for view in cells:
        for frame in view:
            for line in frame:
                for pixel in line:
                    if pixel and pixel not in index_of:
                        index_of[pixel] = len(colors)
                        colors.append(pixel)
    if len(colors) > 256:
        raise ValueError("mais de 256 cores: %d" % len(colors))
    width = CELL * len(VIEWS) * zoom
    height = CELL * zoom
    table = b"".join(bytes(color) for color in colors) + b"\0" * (3 * (256 - len(colors)))
    gif = bytearray(b"GIF89a" + struct.pack("<HHBBB", width, height, 0xF7, 0, 0) + table)
    gif += b"\x21\xff\x0bNETSCAPE2.0\x03\x01\x00\x00\x00"
    for frame in range(frames):
        indices = bytearray()
        for y in range(CELL):
            line = bytearray()
            for view in range(len(VIEWS)):
                for pixel in cells[view][frame][y]:
                    line += bytes((index_of[_opaque(pixel)],)) * zoom
            indices += bytes(line) * zoom
        gif += b"\x21\xf9\x04\x00" + struct.pack("<H", delay) + b"\x00\x00"
        gif += b"\x2c" + struct.pack("<HHHHB", 0, 0, width, height, 0) + b"\x08"
        data = _lzw(indices)
        for start in range(0, len(data), 255):
            piece = data[start:start + 255]
            gif += bytes((len(piece),)) + piece
        gif += b"\x00"
    gif += b"\x3b"
    Path(path).write_bytes(gif)


def build(folder, preview_folder, palette, animations):
    """Escreve idle.png e walk.png em `folder`, e as prévias em `preview_folder`.

    `animations` é {"idle": draw, "walk": draw}, com draw(canvas, view, frame) desenhando
    uma célula, e `view` sendo um dos nomes de VIEWS.
    """
    folder = Path(folder)
    preview_folder = Path(preview_folder)
    preview_folder.mkdir(parents=True, exist_ok=True)
    # Em centésimos de segundo: 5 quadros por segundo no idle, como no Domador.
    delays = {"idle": 20, "walk": 10}
    for name, draw in animations.items():
        frames = FRAMES[name]
        cells = []
        for view in VIEWS:
            line = []
            for frame in range(frames):
                canvas = Canvas(palette)
                draw(canvas, view, frame)
                line.append(canvas.pixels)
            cells.append(line)
        write_png(folder / (name + ".png"), CELL * frames, CELL * len(VIEWS), _sheet_rows(cells, frames))
        _save_preview(preview_folder / (name + "_quadros.png"), cells, frames)
        _save_gif(preview_folder / (name + ".gif"), cells, frames, delays[name])
