"""Lume: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,30 m, ele tem 8 pixels de altura pela regra do mapa (creature-scale): 6 de desenho e
o contorno roxo-escuro por fora. Cabem a bolinha roxa com as duas orelhas de pena, a lua
clara na testa, os olhos dourados de pupila escura, o peito creme, as asinhas com uma pinta
e os pés dourados. O corpo não sobe nem desce: quem se mexe são as asinhas e os pés.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig  # noqa: E402

PALETTE = {
    "o": (26, 20, 56),     # contorno
    "P": (62, 46, 118),    # penas
    "Q": (100, 76, 170),   # penas na luz
    "W": (44, 34, 92),     # asa
    "s": (214, 204, 238),  # pinta da asa
    "C": (240, 228, 216),  # peito e rosto
    "Y": (236, 170, 48),   # olho
    "e": (24, 18, 40),     # pupila e bico
    "M": (246, 226, 150),  # lua
    "F": (226, 162, 56),   # pés
    "q": (112, 70, 22),    # contorno dos pés
}
OUTLINE = {"*": "o", "F": "q"}

TOP = 25
FRONT = [
    "PP.....PP",
    "PQPPMPPQP",
    "PYYCeCYYP",
    "PYeCCCeYP",
    ".PCCCCCP.",
]
LOWER = [
    ".PP...PP.",
    "PPQPPMPQP",
    "PPYYCeYYP",
    "PPYeCCeYP",
    ".PPCCCCP.",
]
SIDE = [
    "....PP...",
    "..PPQPMP.",
    "WPPPPCYYe",
    "WWPPPCCC.",
    ".WPPPCC..",
]
BACK = [
    "PP.....PP",
    "PQPPPPPQP",
    "PPPQQQPPP",
    "PWWPsPWWP",
    ".PWWWWWP.",
]
HEADS = {
    "front": (FRONT, 12, TOP),
    "lower": (LOWER, 12, TOP),
    "side": (SIDE, 11, TOP),
    "upper": (recolored(BACK, "s", "W"), 12, TOP),
    "back": (BACK, 12, TOP),
}
LEG = ["F"]
LEGS = {
    "front": [(14, 0, LEG, 1), (18, 3, LEG, 1)],
    "lower": [(14, 0, LEG, 1), (17, 3, LEG, 1)],
    "side": [(14, 0, LEG, 1), (16, 3, LEG, 1)],
    "upper": [(14, 0, LEG, 1), (17, 3, LEG, 1)],
    "back": [(14, 0, LEG, 1), (18, 3, LEG, 1)],
}
DOWN = [".", "W"]
UP = ["W", "."]
FLAP = [DOWN, UP, DOWN, DOWN]
FLAP_LATE = [DOWN, DOWN, UP, DOWN]
LEFT_WING_AT = {"front": (11, 27), "lower": (11, 27), "upper": (11, 27), "back": (11, 27)}
RIGHT_WING_AT = {"front": (21, 27), "back": (21, 27)}
SIDE_WING_AT = {"side": (14, 28)}
TRAITS = [
    {"frames": FLAP, "at": LEFT_WING_AT},
    {"frames": FLAP_LATE, "at": RIGHT_WING_AT},
    {"frames": [["s"], ["W"], ["s"], ["s"]], "at": SIDE_WING_AT},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, {}, LEGS, 30, TRAITS, idle_head=(0, 0, 0, 0), idle_body=(0, 0, 0, 0), walk_head=(0, 0, 0, 0, 0, 0), walk_body=(0, 0, 0, 0, 0, 0), foot_reach=(1, 0, -1, -1, 0, 1), foot_lift=(0, 0, 0, 0, 0, 0)),
        outline=OUTLINE,
    )
