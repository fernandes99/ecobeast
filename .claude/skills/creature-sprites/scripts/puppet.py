"""Boneco de peças para as folhas da luta (board-battle/07), só com a biblioteca padrão.

Um Ecobeast é montado com elipsoides (cabeça, focinho, corpo, patas, cauda...), num
espaço próprio dele: x para a frente, y para cima e z para o lado direito, em pixels
da arte, com os pés em y = 0. O renderizador vira o boneco para cada vista, projeta numa
câmera um pouco de cima (como a vista "low top-down"), pinta cada peça em 3 tons pela
luz e desenha o contorno. Olhos, focinho e outros detalhes pequenos são carimbos à mão,
colados no ponto da superfície em que caem, quando esse ponto está à vista.

Assim as 5 vistas saem coerentes entre si, e as animações só movem as peças.
"""
import math
import struct
import zlib
from pathlib import Path

PITCH = math.radians(18)
COS_P = math.cos(PITCH)
SIN_P = math.sin(PITCH)
# Para onde o Ecobeast olha em cada vista, no plano do chão (x para a direita da tela,
# z na direção de quem olha a tela).
FACING = {
    "south": (0.0, 1.0),
    "south-east": (math.sqrt(0.5), math.sqrt(0.5)),
    "east": (1.0, 0.0),
    "north-east": (math.sqrt(0.5), -math.sqrt(0.5)),
    "north": (0.0, -1.0),
}
LIGHT = None  # calculada abaixo
# Uma linha de profundidade maior que isto entre dois pixels vizinhos vira contorno.
DEPTH_EDGE = 3.5


def _norm(v):
    length = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]) or 1.0
    return (v[0] / length, v[1] / length, v[2] / length)


def _dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


def _add(a, b, k=1.0):
    return (a[0] + b[0] * k, a[1] + b[1] * k, a[2] + b[2] * k)


LIGHT = _norm((-0.55, 0.85, 0.55))
TOWARD_VIEWER = (0.0, SIN_P, COS_P)


def rotation(yaw=0.0, pitch=0.0, roll=0.0):
    """Os 3 eixos de uma peça, no espaço do Ecobeast: primeiro inclina para cima
    (`pitch`, em graus, girando em torno do eixo do lado), depois gira para os lados
    (`yaw`, em torno do eixo de cima) e por fim tomba (`roll`, em torno da frente)."""
    p, y, r = math.radians(pitch), math.radians(yaw), math.radians(roll)

    def apply(v):
        # pitch em torno de z
        x, yy, z = v
        x, yy = x * math.cos(p) - yy * math.sin(p), x * math.sin(p) + yy * math.cos(p)
        # roll em torno de x
        yy, z = yy * math.cos(r) - z * math.sin(r), yy * math.sin(r) + z * math.cos(r)
        # yaw em torno de y
        x, z = x * math.cos(y) + z * math.sin(y), -x * math.sin(y) + z * math.cos(y)
        return (x, yy, z)

    return (apply((1, 0, 0)), apply((0, 1, 0)), apply((0, 0, 1)))


class Part:
    """Uma elipsoide: centro, raios nos 3 eixos e a cor.

    `paint` é o nome de uma rampa de cores, ou uma função (u) -> nome, em que u é o
    ponto atingido no espaço da esfera unitária da peça (u[0] para a frente da peça,
    u[1] para cima e u[2] para o lado). `glow` pinta pela posição em vez da luz, para
    as chamas. `outline` é a chave da cor do contorno dela."""

    def __init__(self, center, radii, paint, axes=None, glow=None, outline="K", tag=""):
        self.center = center
        self.radii = radii
        self.paint = paint
        self.axes = axes or ((1, 0, 0), (0, 1, 0), (0, 0, 1))
        self.glow = glow
        self.outline = outline
        self.tag = tag


def chain(points, radii, paint, step=0.8, **kw):
    """Uma peça comprida e curva (pata, cauda, orelha): esferas ao longo dos pontos,
    com o raio indo de um valor ao outro."""
    parts = []
    total = sum(math.dist(points[i], points[i + 1]) for i in range(len(points) - 1))
    walked = 0.0
    for i in range(len(points) - 1):
        a, b = points[i], points[i + 1]
        length = math.dist(a, b)
        count = max(1, int(length / step))
        for k in range(count + (1 if i == len(points) - 2 else 0)):
            t = k / count
            position = (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t)
            share = (walked + length * t) / total if total else 0.0
            radius = radii[0] + (radii[1] - radii[0]) * share
            parts.append(Part(position, (radius, radius, radius), paint, **kw))
        walked += length
    return parts


def leg(hip, foot, length, bend, radii, paint, **kw):
    """Uma pata de dois ossos, do quadril ao pé, com o joelho dobrando para `bend`
    (+1 para a frente, -1 para trás)."""
    d = math.dist(hip, foot)
    half = length / 2.0
    lift = math.sqrt(max(0.0, half * half - (d / 2.0) ** 2))
    mid = ((hip[0] + foot[0]) / 2.0 + bend * lift, (hip[1] + foot[1]) / 2.0, (hip[2] + foot[2]) / 2.0)
    return chain([hip, mid, foot], radii, paint, **kw)


class Decal:
    """Um carimbo à mão (olho, focinho) colado num ponto da superfície.

    `stamps` é {"front": linhas, "side": linhas, ...}: o renderizador escolhe pelo
    quanto o ponto está de frente para quem olha. O ponto do carimbo indicado por
    `anchor` (coluna, linha) cai sobre o pixel do ponto. `mirror` espelha o carimbo
    (o olho do outro lado do rosto)."""

    def __init__(self, point, normal, stamps, anchor=(0, 0), mirror=False, on="", min_facing=0.15):
        self.point = point
        self.normal = normal
        self.stamps = stamps
        self.anchor = anchor
        self.mirror = mirror
        self.on = on
        self.min_facing = min_facing


class Renderer:
    def __init__(self, palette, ramps, cell=64, ground_row=56):
        self.palette = palette
        self.ramps = ramps
        self.cell = cell
        self.ground_row = ground_row

    def _basis(self, view):
        fx, fz = FACING[view]
        forward = (fx, 0.0, fz)
        up = (0.0, 1.0, 0.0)
        # O lado direito do Ecobeast: frente × cima.
        right = (forward[1] * up[2] - forward[2] * up[1], forward[2] * up[0] - forward[0] * up[2], forward[0] * up[1] - forward[1] * up[0])
        return forward, up, right

    def _to_world(self, basis, v):
        f, u, r = basis
        return (f[0] * v[0] + u[0] * v[1] + r[0] * v[2], f[1] * v[0] + u[1] * v[1] + r[1] * v[2], f[2] * v[0] + u[2] * v[1] + r[2] * v[2])

    def _screen(self, p):
        """(coluna, linha) contínuas e a profundidade (maior = mais perto)."""
        sx = p[0] + self.cell / 2.0
        sy = self.ground_row - (p[1] * COS_P - p[2] * SIN_P)
        return sx, sy, _dot(p, TOWARD_VIEWER)

    def render(self, view, parts, decals=()):
        basis = self._basis(view)
        size = self.cell
        depth = [[-1e9] * size for _ in range(size)]
        color = [[None] * size for _ in range(size)]
        owner = [[None] * size for _ in range(size)]
        for part in parts:
            center = self._to_world(basis, part.center)
            axes = [self._to_world(basis, a) for a in part.axes]
            reach = max(part.radii)
            cx, cy, _ = self._screen(center)
            x0, x1 = max(0, int(cx - reach - 1)), min(size - 1, int(cx + reach + 1))
            y0, y1 = max(0, int(cy - reach - 1)), min(size - 1, int(cy + reach + 1))
            # A direção do raio, no espaço da esfera unitária da peça.
            qd = tuple(_dot(TOWARD_VIEWER, axes[i]) / part.radii[i] for i in range(3))
            a = _dot(qd, qd)
            for row in range(y0, y1 + 1):
                for col in range(x0, x1 + 1):
                    # O ponto do raio deste pixel que fica no plano da tela que passa pela origem.
                    sx = col + 0.5 - size / 2.0
                    sy = self.ground_row - (row + 0.5)
                    origin = (sx, sy * COS_P, -sy * SIN_P)
                    rel = (origin[0] - center[0], origin[1] - center[1], origin[2] - center[2])
                    q0 = tuple(_dot(rel, axes[i]) / part.radii[i] for i in range(3))
                    b = 2.0 * _dot(q0, qd)
                    c = _dot(q0, q0) - 1.0
                    disc = b * b - 4.0 * a * c
                    if disc < 0.0:
                        continue
                    t = (-b + math.sqrt(disc)) / (2.0 * a)
                    if t <= depth[row][col]:
                        continue
                    u = _add(q0, qd, t)
                    normal = _norm(tuple(sum(u[i] / part.radii[i] * axes[i][k] for i in range(3)) for k in range(3)))
                    depth[row][col] = t
                    color[row][col] = self._shade(part, u, normal)
                    owner[row][col] = part
        self._decals(basis, decals, depth, color, owner)
        return self._outline(depth, color, owner)

    def _shade(self, part, u, normal):
        if part.glow is not None:
            return part.glow(u)
        name = part.paint(u) if callable(part.paint) else part.paint
        ramp = self.ramps[name]
        light = _dot(normal, LIGHT)
        if light > 0.62:
            return ramp[2]
        if light > 0.12:
            return ramp[1]
        return ramp[0]

    def _decals(self, basis, decals, depth, color, owner):
        # O quanto a cabeça olha para quem vê a tela: de frente, meio de lado, de lado.
        toward = basis[0][2]
        view_key = "front" if toward > 0.85 else "turned" if toward > 0.3 else "side"
        for decal in decals:
            point = self._to_world(basis, decal.point)
            normal = self._to_world(basis, decal.normal)
            facing = _dot(_norm(normal), TOWARD_VIEWER)
            if facing < decal.min_facing:
                continue
            sx, sy, t = self._screen(point)
            col, row = int(sx), int(sy)
            if not (0 <= row < self.cell and 0 <= col < self.cell):
                continue
            # Escondido atrás de outra peça (como o olho do lado de lá, atrás do focinho).
            if depth[row][col] > t + 2.5:
                continue
            stamp = decal.stamps.get(view_key) or decal.stamps.get("front")
            # De frente, o carimbo do outro lado do rosto é espelhado.
            mirror = decal.mirror and view_key == "front"
            ax, ay = decal.anchor
            for dy, line in enumerate(stamp):
                for dx, key_char in enumerate(line):
                    if key_char == ".":
                        continue
                    x = col + ((len(line) - 1 - dx) - (len(line) - 1 - ax) if mirror else dx - ax)
                    y = row + dy - ay
                    if 0 <= y < self.cell and 0 <= x < self.cell and color[y][x] is not None:
                        color[y][x] = self.palette[key_char]

    def _outline(self, depth, color, owner):
        size = self.cell
        out = [[None] * size for _ in range(size)]
        for row in range(size):
            for col in range(size):
                if color[row][col] is not None:
                    out[row][col] = color[row][col]
        for row in range(size):
            for col in range(size):
                here = owner[row][col]
                if here is None:
                    # Contorno de fora: um pixel transparente encostado em alguém.
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        x, y = col + dx, row + dy
                        if 0 <= x < size and 0 <= y < size and owner[y][x] is not None:
                            out[row][col] = self.palette[owner[y][x].outline]
                            break
                    continue
                # Contorno de dentro: o pixel de trás, quando o vizinho está bem na frente.
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    x, y = col + dx, row + dy
                    if 0 <= x < size and 0 <= y < size and owner[y][x] is not None:
                        if depth[y][x] - depth[row][col] > DEPTH_EDGE and owner[y][x].tag != here.tag:
                            out[row][col] = self.palette[owner[y][x].outline]
                            break
        return out


def to_rows(image):
    rows = []
    for line in image:
        row = bytearray()
        for pixel in line:
            row += bytes(pixel) + b"\xff" if pixel is not None else b"\0\0\0\0"
        rows.append(bytes(row))
    return rows


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


def write_sheet(path, lines, cell):
    """Uma folha com uma linha por vista; `lines` é [[quadro, ...], ...]."""
    columns = max(len(frames) for frames in lines)
    rows = []
    for frames in lines:
        images = [to_rows(frame) for frame in frames]
        for y in range(cell):
            row = b"".join(image[y] for image in images)
            rows.append(row + bytes((columns - len(frames)) * cell * 4))
    write_png(path, cell * columns, cell * len(lines), rows)


def write_preview(path, lines, cell, zoom=4, background=(88, 102, 116)):
    """As vistas lado a lado, ampliadas, num fundo cinza, para olhar fora do jogo."""
    columns = max(len(frames) for frames in lines)
    width, height = cell * columns * zoom, cell * len(lines) * zoom
    rows = []
    for frames in lines:
        for y in range(cell):
            row = bytearray()
            for x in range(columns):
                frame = frames[x] if x < len(frames) else None
                for xx in range(cell):
                    pixel = frame[y][xx] if frame is not None else None
                    row += bytes(pixel if pixel is not None else background) * zoom
            line = bytes(b"".join(row[i:i + 3] + b"\xff" for i in range(0, len(row), 3)))
            rows += [line] * zoom
    write_png(path, width, height, rows)
