"""Reduz o front.png de uma criatura e lista as cores dele, para servir de referência.

Uso: python reference.py <front.png> <saida.png> [tamanho]

A redução borra: ela serve para ver proporções e tirar a paleta, não para ir para a folha.
"""
import sys
from collections import Counter
from pathlib import Path

# Com `python -I`, a pasta do script não entra na busca de módulos.
sys.path.insert(0, str(Path(__file__).resolve().parent))

from spritekit import read_png, write_png  # noqa: E402


def main():
    source, output = sys.argv[1], sys.argv[2]
    target = int(sys.argv[3]) if len(sys.argv) > 3 else 30
    width, height, rows = read_png(source)
    xs = []
    ys = []
    for y in range(height):
        line = rows[y]
        for x in range(width):
            if line[x * 4 + 3] > 128:
                xs.append(x)
                ys.append(y)
    left, right, top, bottom = min(xs), max(xs), min(ys), max(ys)
    print("original %dx%d, a criatura ocupa x %d-%d, y %d-%d" % (width, height, left, right, top, bottom))
    step = max(right - left + 1, bottom - top + 1) / target
    small = []
    colors = Counter()
    for j in range(target):
        line = []
        for i in range(target):
            red = green = blue = alpha = count = 0
            for y in range(int(top + j * step), min(height, int(top + (j + 1) * step))):
                for x in range(int(left + i * step), min(width, int(left + (i + 1) * step))):
                    r, g, b, a = rows[y][x * 4:x * 4 + 4]
                    red += r * a
                    green += g * a
                    blue += b * a
                    alpha += a
                    count += 1
            if alpha / max(count, 1) < 110:
                line.append(None)
            else:
                color = (red // alpha, green // alpha, blue // alpha)
                line.append(color)
                colors[(color[0] // 24 * 24, color[1] // 24 * 24, color[2] // 24 * 24)] += 1
        small.append(line)
    zoom = 10
    picture = []
    for line in small:
        row = bytearray()
        for color in line:
            row += (bytes(color) + b"\xff" if color else b"\xdd\xdd\xdd\xff") * zoom
        for _ in range(zoom):
            picture.append(bytes(row))
    write_png(output, target * zoom, len(picture), picture)
    print("cores mais usadas:")
    for color, count in colors.most_common(16):
        print("  #%02x%02x%02x  %d" % (color + (count,)))


if __name__ == "__main__":
    main()
