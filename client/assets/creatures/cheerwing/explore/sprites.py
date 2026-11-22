"""Cheerwing: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,6 m, ela tem 13 pixels de altura pela regra do mapa (creature-scale): 11 de desenho e
o contorno roxo-escuro por fora. Cabem as asas abertas roxas, rosa e creme com a pinta
dourada, as antenas de bolinha rosa, o topete rosa e dourado, a cabeça lilás de olho magenta,
o peito de penugem creme e o corpo roxo fino de pernas compridas, que encostam no chão. Só as
asas batem (abertas, no meio e erguidas), e a pinta dourada pisca de alegria.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, mirrored, recolored  # noqa: E402

PALETTE = {
    "o": (58, 20, 86),     # contorno
    "V": (126, 64, 198),   # asa
    "v": (84, 34, 148),    # asa na sombra
    "P": (246, 112, 172),  # rosa
    "c": (252, 234, 198),  # creme
    "C": (232, 196, 160),  # creme na sombra
    "Y": (252, 206, 104),  # ouro
    "y": (255, 244, 196),  # ouro aceso
    "H": (180, 124, 232),  # cabeça
    "E": (196, 30, 120),   # olho
    "m": (74, 32, 116),    # corpo
    "R": (234, 98, 192),   # bolinha da antena
}
OUTLINE = {"*": "o"}
TOP = 20

FRONT_BODY = mirrored([
    "R...",
    ".m..",
    "..YP",
    ".HHH",
    "HEHH",
    ".HHc",
    "cccc",
    ".ccC",
    "..mm",
    "..m.",
    ".m..",
])
WING_OPEN = mirrored([
    "vvv......",
    "VVVVv....",
    "VYPPVv...",
    "VPccPVv..",
    "VPcPPVv..",
    ".VPPVv...",
    "..vPPv...",
    "..vPVv...",
    "...vv....",
])
WING_RAISED = mirrored([
    "...vv....",
    "..vVVv...",
    "..VYPVv..",
    ".VPccPv..",
    ".VPcPVv..",
    "..VPPv...",
    "...vPv...",
    "...vPv...",
    "....v....",
])
FRONT_WINGS = [
    (WING_OPEN, 7, TOP + 2),
    (WING_OPEN, 7, TOP + 1),
    (WING_RAISED, 7, TOP),
]

SIDE_BODY = [
    "...R.R",
    "...m.m",
    "..YPm.",
    "..HHHH",
    "..HHEH",
    "...cHH",
    "..cccc",
    "...ccC",
    "...mm.",
    "...m.m",
    "..m..m",
]
SIDE_OPEN = [
    "..vvv....",
    ".vVVVVv..",
    "vVYPPVVv.",
    "VPccPPVV.",
    "VPcccPVv.",
    ".VPPPPVv.",
    "..vVPPv..",
    "..vPPv...",
    "...vv....",
]
SIDE_RAISED = [
    "...vv...",
    "..vVVv..",
    "..VYPVv.",
    ".VPccPv.",
    ".VPccPV.",
    "..VPPVv.",
    "...vPv..",
    "...vPv..",
    "....v...",
]
SIDE_WINGS = [
    (SIDE_OPEN, 8, TOP + 2),
    (SIDE_OPEN, 9, TOP + 1),
    (SIDE_RAISED, 10, TOP),
]


def faceless(drawing):
    return recolored(drawing, "E", "H")


PARTS = {
    "front": (FRONT_WINGS, [(FRONT_BODY, 13, TOP)]),
    "side": (SIDE_WINGS, [(SIDE_BODY, 14, TOP)]),
    "back": (
        [(recolored(d, "c", "C"), x, y) for d, x, y in FRONT_WINGS],
        [(recolored(FRONT_BODY, "EYc", "HHm"), 13, TOP)],
    ),
}
PARTS["lower"] = PARTS["side"]
PARTS["upper"] = (SIDE_WINGS, [(faceless(SIDE_BODY), 14, TOP)])
IDLE = (0, 1, 2, 1)
WALK = (0, 1, 2, 0, 1, 2)


def drawer(poses):
    def draw(canvas, view, frame):
        wings, parts = PARTS[view]
        drawing, left, top = wings[poses[frame]]
        if frame % 2:
            drawing = recolored(drawing, "Y", "y")
        canvas.stamp(drawing, left, top)
        for part, left, top in parts:
            canvas.stamp(part, left, top)

    return draw


if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, {"idle": drawer(IDLE), "walk": drawer(WALK)}, outline=OUTLINE)
