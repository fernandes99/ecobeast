"""Glimshell: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,35 m, ele tem 9 pixels de altura pela regra do mapa (creature-scale): 7 de desenho e
o contorno marrom por fora. Cabem o casco âmbar facetado com a pedrinha clara no topo, a
cabeça grande e dourada de olhos meio fechados e as patas curtas. No idle, ele cochila
(os olhos fecham) e a pedrinha pisca; no walk, as patas andam em diagonais, devagar.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build  # noqa: E402

PALETTE = {
    "o": (72, 30, 16),     # contorno
    "W": (252, 240, 184),  # pedrinha clara
    "A": (244, 178, 60),   # cristal na luz
    "M": (220, 122, 46),   # cristal âmbar
    "a": (150, 70, 26),    # aresta das facetas
    "G": (240, 190, 76),   # pele dourada
    "g": (196, 128, 42),   # pele na sombra
    "E": (52, 20, 10),     # olho
}
OUTLINE = {"*": "o"}

SIDE = [
    "....W......",
    "..MAWAM....",
    ".MAaAAaMGG.",
    "MAaAMaAMGEG",
    "aaaaaaaaGGg",
    ".gG...gG...",
]
FRONT = [
    ".....W.....",
    "...MAWAM...",
    ".MAaAAAaAM.",
    "MAaAGGGAaAM",
    "aaaGEGEGaaa",
    ".gG.gGg.Gg.",
]
BACK = [
    ".....W.....",
    "...MAWAM...",
    ".MAaAAAaAM.",
    "MAaAMaMAaAM",
    "aaaaaaaaaaa",
    ".gG..g..Gg.",
]
# Os pés na última linha, por quadro do walk: as diagonais se revezam.
SIDE_FEET = [".gG...gG...", "..gG..gG...", "..gG...gG..", ".gG...gG...", ".gG..gG....", "gG....gG..."]
FRONT_FEET = [".gG.....Gg.", ".gG......Gg", "gG.......Gg", ".gG.....Gg.", "..gG....Gg.", "..gG...Gg.."]
SIDE_IDLE_FEET = ".gG...gG..."
FRONT_IDLE_FEET = ".gG.....Gg."

VIEWS = {"front": FRONT, "lower": SIDE, "side": SIDE, "upper": SIDE, "back": BACK}
LEFT = {"front": 10, "lower": 10, "side": 10, "upper": 10, "back": 10}
TOP = 24


def drawing(view, sparkle, sleepy, feet):
    rows = list(VIEWS[view])
    if view == "upper":
        rows = [row.replace("E", "G") for row in rows]
    if sleepy:
        rows = [row.replace("E", "g") for row in rows]
    if sparkle:
        rows[0] = rows[0].replace("W", "A")
        rows[1] = rows[1].replace("AWA", "WAW")
    side = view in ("lower", "side", "upper")
    if feet is None:
        feet = SIDE_IDLE_FEET if side else FRONT_IDLE_FEET
    else:
        feet = (SIDE_FEET if side else FRONT_FEET)[feet]
    return rows + [feet]


def draw_idle(canvas, view, frame):
    canvas.stamp(drawing(view, frame in (1, 3), frame in (1, 2), None), LEFT[view], TOP)


def draw_walk(canvas, view, frame):
    canvas.stamp(drawing(view, frame >= 3, False, frame), LEFT[view], TOP)


if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, {"idle": draw_idle, "walk": draw_walk}, outline=OUTLINE)
