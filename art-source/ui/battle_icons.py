"""Recorta os ícones da tela da luta (board-battle/10) da imagem que o dono mandou
em 2026-11-06 (battle_icons.png, 612 × 408, fundo transparente, 9 ícones). A bola
de captura e a engrenagem ficam de fora: a bola repete o desenho de outra franquia,
o que as regras do projeto proíbem, e a engrenagem não tem uso na luta.

Cada ícone sai justo, com uma margem de PADDING pixels, no tamanho original: o
Godot o reduz com filtro suave, porque não é pixel art.

Uso, na raiz do repositório: python -I art-source/ui/battle_icons.py
Escreve client/assets/ui/battle/icons/*.png.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))
from spritekit import read_png, write_png  # noqa: E402

SOURCE = Path(__file__).resolve().parent / "battle_icons.png"
OUT = ROOT / "client/assets/ui/battle/icons"
PADDING = 2
## Nome no jogo: a caixa onde o ícone está (x0, y0, x1, y1), achada pelas colunas e
## linhas vazias da imagem.
ICONS = {
    "attack": (31, 53, 150, 178),
    "bag": (184, 53, 301, 178),
    "flee": (476, 53, 593, 178),
    "help": (31, 220, 113, 334),
    "pass": (277, 220, 374, 334),
    "chat": (391, 220, 496, 334),
    "more": (516, 220, 596, 334),
}


def tight(rows, box):
    """O retângulo dos pixels visíveis dentro da caixa."""
    x0, y0, x1, y1 = box
    xs, ys = [], []
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if rows[y][x * 4 + 3] > 8:
                xs.append(x)
                ys.append(y)
    return min(xs), min(ys), max(xs), max(ys)


width, height, rows = read_png(SOURCE)
OUT.mkdir(parents=True, exist_ok=True)
for name, box in ICONS.items():
    x0, y0, x1, y1 = tight(rows, box)
    w = x1 - x0 + 1 + PADDING * 2
    h = y1 - y0 + 1 + PADDING * 2
    out = []
    for y in range(y0 - PADDING, y1 + PADDING + 1):
        line = bytearray()
        for x in range(x0 - PADDING, x1 + PADDING + 1):
            inside = 0 <= x < width and 0 <= y < height
            line += bytes(rows[y][x * 4:x * 4 + 4]) if inside else b"\0\0\0\0"
        out.append(bytes(line))
    write_png(OUT / ("%s.png" % name), w, h, out)
    print("ok: %s.png  %d x %d" % (name, w, h))
