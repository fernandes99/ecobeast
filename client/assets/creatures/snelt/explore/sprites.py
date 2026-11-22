"""Snelt: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,30 m, ele tem 8 pixels de altura pela regra do mapa (creature-scale): 6 de desenho e
o contorno marrom-escuro por fora. Cabem a concha de ferro com a espiral de brasa, a brasa
acesa no topo, o corpo bege, o olho e as duas antenas de ponta acesa. Sem patas, ele anda
esticando o pé: a cabeça vai à frente e a concha chega um quadro depois.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build  # noqa: E402

PALETTE = {
    "o": (48, 28, 26),     # contorno
    "m": (72, 62, 66),     # ferro na sombra
    "M": (112, 100, 102),  # ferro
    "I": (164, 152, 150),  # ferro na luz
    "F": (250, 132, 28),   # brasa
    "Y": (255, 214, 88),   # brasa acesa
    "B": (218, 198, 176),  # corpo
    "b": (168, 144, 124),  # corpo na sombra
    "k": (52, 30, 24),     # olho
}
OUTLINE = {"*": "o"}
BOTTOM = 30

# Coluna onde a concha acaba e começa a cabeça: no walk, as duas partes andam separadas.
SIDE = [
    "..mFm...Y.Y.",
    ".mIMIm..b.b.",
    "mIFFmIm.BBB.",
    "mIFmFMmBBkBB",
    ".mMFFMmBBBBB",
    "bBBBBBBBBBBb",
]
SIDE_SPLIT = 7
UPPER = [row.replace("k", "B") for row in SIDE]
FRONT = [
    "..Y.mFm.Y.",
    "..bmIIIMb.",
    ".mIBBBBIm.",
    ".mBkBBkBm.",
    ".mBBBBBBm.",
    "bbBBBBBBbb",
]
BACK = [
    "..Y.mFm.Y.",
    "..mIIIIMm.",
    ".mIFmmFMm.",
    ".mIFFmFMm.",
    ".mMmFFMmm.",
    "bbbbbbbbbb",
]
VIEW_ART = {
    "front": (FRONT, None),
    "lower": (SIDE, SIDE_SPLIT),
    "side": (SIDE, SIDE_SPLIT),
    "upper": (UPPER, SIDE_SPLIT),
    "back": (BACK, None),
}

IDLE_TIPS = (0, 1, 0, -1)
WALK_HEAD = (0, 1, 1, 1, 0, 0)
WALK_SHELL = (0, 0, 0, 1, 1, 0)
WALK_TIPS = (0, 0, 1, 0, 0, -1)


def stretched_side(art, split, head_dx, shell_dx):
    """A cabeça anda `head_dx` e a concha `shell_dx`; o vão do pé e do pescoço é preenchido."""
    rows = []
    for row in art:
        back, front = row[:split], row[split:]
        line = ["."] * (len(row) + 2)
        for i, mark in enumerate(back):
            line[i + shell_dx] = mark
        for i, mark in enumerate(front):
            line[split + head_dx + i] = mark
        if back[-1] != "." and front[0] != ".":
            for x in range(split + shell_dx, split + head_dx):
                line[x] = front[0]
        rows.append("".join(line))
    return rows


def glowing(art, lit):
    """A brasa pisca: troca a brasa pela acesa nos quadros pares."""
    return [row.replace("F", "Y") for row in art] if lit else art


def swayed_tips(art, dx):
    """As pontas das antenas, na primeira linha, balançam `dx` colunas."""
    if dx == 0:
        return art
    top = art[0]
    tips = "".join(m if m == "Y" else "." for m in top)
    rest = "".join("." if m == "Y" else m for m in top)
    moved = ("." * dx + tips[:-dx]) if dx > 0 else (tips[-dx:] + "." * -dx)
    merged = "".join(t if t != "." else r for t, r in zip(moved, rest))
    return [merged] + art[1:]


def draw(canvas, view, frame, walking):
    art, split = VIEW_ART[view]
    tips = (WALK_TIPS if walking else IDLE_TIPS)[frame]
    if walking and split is not None:
        art = stretched_side(art, split, WALK_HEAD[frame], WALK_SHELL[frame])
    elif walking:
        # De frente e de costas, o pé alarga e volta.
        foot = art[-1]
        edge = foot[0] if WALK_HEAD[frame] else "."
        art = ["." + row + "." for row in art[:-1]] + [edge + foot + edge]
    art = swayed_tips(glowing(art, frame % 2 == 0), tips)
    width = max(len(row) for row in art)
    canvas.stamp(art, 16 - width // 2, BOTTOM - len(art) + 1)


if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        {"idle": lambda c, v, f: draw(c, v, f, False), "walk": lambda c, v, f: draw(c, v, f, True)},
        outline=OUTLINE,
    )
