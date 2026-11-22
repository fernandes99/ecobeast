"""Galafly: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,3 m, ela tem 23 pixels de altura pela regra do mapa (creature-scale): 21 de desenho e
o contorno roxo-escuro por fora. Cabem as quatro asas largas em faixas roxas, rosa, creme e
douradas, com as pintas e a estrela douradas, as antenas de bolinha rosa, a crista de
pétalas, a cabeça lilás de olho magenta e bico dourado, o peito de pétalas creme e rosa, o
corpo roxo e as caudas rosa das asas de trás, que encostam no chão. Só as asas batem
(abertas, no meio e erguidas), e as pintas douradas piscam como confete.
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
    "L": (190, 146, 242),  # lilás
    "P": (246, 112, 172),  # rosa
    "p": (204, 66, 138),   # rosa na sombra
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
TOP = 10

FRONT_BODY = mirrored([
    "R.....",
    ".m....",
    "..mPYP",
    "...PYP",
    "...HHH",
    "..HEHH",
    "...HHY",
    "..cPcc",
    ".PcccC",
    "PcccCc",
    ".PcCcc",
    "..mmmm",
    "..mvmm",
    "...mmm",
    "...mvm",
    "....mm",
])
FRONT_TAILS = mirrored([
    ".P....",
    ".P....",
    "P.....",
    "pP....",
    "pP....",
    ".p....",
])
WING_OPEN = [
    "..vvvv..........",
    ".vVYVVvv........",
    "vVVPPPVVv.......",
    "VYPccPPVVv......",
    "VPcYYcPLVVv.....",
    "VPcccPLLVVVv....",
    "VVPccPLLVVVVv...",
    ".VVPPLLVVVVVVv..",
    "..vVVVVVVVvvvv..",
    "...vPPPVVvv.....",
    "..vPccPVv.......",
    ".vPcYcPv........",
    ".vPccPVv........",
    "..vPPvv.........",
    "...vv...........",
]
WING_RAISED = [
    ".......vvv......",
    "......vVYVv.....",
    ".....vVPPPVv....",
    ".....VPccPVv....",
    "....VPcYYcPVv...",
    "....VPcccPLVVv..",
    "....VVPccPLVVv..",
    ".....VVPPLLVVv..",
    "......vVVVVVVv..",
    ".......vPPVvv...",
    "......vPccPv....",
    ".....vPcYcPv....",
    ".....vPccPv.....",
    "......vPPv......",
    ".......vv.......",
]
FRONT_WINGS = [
    (mirrored([row[1:] for row in WING_OPEN]), 1, TOP + 2),
    (mirrored([row[2:] for row in WING_OPEN]), 2, TOP + 1),
    (mirrored([row[1:] for row in WING_RAISED]), 1, TOP),
]

SIDE_BODY = [
    "....RR.RR.",
    ".....m.m..",
    "....PYPm..",
    "....YHHHH.",
    "....HHHEH.",
    ".....HHHYY",
    "....PcPHH.",
    "...PcccP..",
    "...cPcCcP.",
    "....cPcC..",
    "....mmmm..",
    "....mvmm..",
    "....mmmm..",
    ".....mvm..",
    ".....mm...",
]
SIDE_TAILS = [
    "..P...P...",
    ".P...P....",
    ".P...P....",
    "pP..pP....",
    "pP..pP....",
    ".p...p....",
    ".p...p....",
]
SIDE_OPEN = [
    "...vvvvv......",
    "..vVYVVVvv....",
    ".vVPPPPVVVv...",
    "vVPccccPLVVv..",
    "VPcYccYcPLVVv.",
    "VPccYYccPLVVVv",
    "VVPccccPLLVVVv",
    ".VVPPPPLLVVVv.",
    "..vVVVVVVVvv..",
    "...vPPPVvv....",
    "..vPccPVv.....",
    ".vPcYcPv......",
    ".vPPcPv.......",
    "..vvvv........",
]
SIDE_RAISED = [
    ".....vvv....",
    "....vVYVv...",
    "...vVPPPVv..",
    "...VPcccPVv.",
    "..VPcYYcPLVv",
    "..VPccccPLVv",
    "..VVPccPLLVv",
    "...VVPPLLVVv",
    "....vVVVVVv.",
    ".....vPPPv..",
    "....vPccv...",
    "...vPcYv....",
    "...vPPv.....",
]
SIDE_WINGS = [
    (SIDE_OPEN, 3, TOP + 2),
    (SIDE_OPEN, 4, TOP + 1),
    (SIDE_RAISED, 6, TOP),
]


def faceless(drawing):
    return recolored(drawing, "EY", "HH")


PARTS = {
    "front": (FRONT_WINGS, [(FRONT_BODY, 10, TOP), (FRONT_TAILS, 10, TOP + 15)]),
    "side": (SIDE_WINGS, [(SIDE_TAILS, 9, TOP + 14), (SIDE_BODY, 13, TOP)]),
    "back": (
        [(recolored(d, "c", "C"), x, y) for d, x, y in FRONT_WINGS],
        [(recolored(FRONT_BODY, "EYcP", "HHmm"), 10, TOP), (FRONT_TAILS, 10, TOP + 15)],
    ),
}
PARTS["lower"] = PARTS["side"]
PARTS["upper"] = (SIDE_WINGS, [(SIDE_TAILS, 9, TOP + 14), (faceless(SIDE_BODY), 13, TOP)])
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
